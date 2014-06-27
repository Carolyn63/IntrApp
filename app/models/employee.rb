require 'digest/md5'
require 'aasm'

class Employee < ActiveRecord::Base

	cattr_reader :per_page
	@@per_page = 30

	module Status
		PENDING = "pending"
		ACTIVE = "active"
		REJECTED = "rejected"

		ALL = [PENDING, ACTIVE, REJECTED]

		LIST = [
			[I18n.t('models.employee.active_employees'), ACTIVE],
			[I18n.t('models.employee.pending_employees'), PENDING],
			[I18n.t('models.employee.rejected_employees'), REJECTED]
		]

		EMPLOYERS_LIST = [
			[I18n.t('models.employee.active_employees'), ACTIVE],
			[I18n.t('models.employee.pending_employees'), PENDING],
			[I18n.t('models.employee.rejected_employees'), REJECTED]
		]

		TO_LIST = {
			PENDING => I18n.t('models.employee.pending_employees'),
			ACTIVE => I18n.t('models.employee.active_employees'),
			REJECTED => I18n.t('models.employee.rejected_employees')
		}
		TO_PAGE_TITLE = {
			"" => I18n.t('views.employees.active_employee_page_title'),
			ACTIVE => I18n.t('views.employees.active_employee_page_title'),
			PENDING => I18n.t('views.employees.pending_employee_page_title'),
			REJECTED => I18n.t('views.employees.rejected_employee_page_title'),
		}
	end

	act_as_services_delete_audit :additional_audited_columns => %w{created_at company_id user_id id company_email}

	belongs_to :user
	belongs_to :company
	belongs_to :department
	has_one    :ippbx, :dependent => :destroy, :foreign_key => "employee_id"
	has_one    :cloudstorage
	
	has_many :employee_applications, :dependent => :destroy
	has_many :applications, :through => :employee_applications

	has_many :employee_devices, :dependent => :destroy
	has_many :devices, :through => :employee_devices
	# has_one :audit, :as => :auditable, :order => "created_at DESC"

	validates_presence_of :company_email
	#validates_presence_of :email_password, :email_password_confirmation, :if => :require_password?
	#validates_length_of :email_password, :email_password_confirmation, :minimum => 6, :if => :require_password?
	#validates_confirmation_of :email_password, :if => :require_password?
	#validates_length_of :job_title, :in => 1..128
	validates_length_of :company_email, :within => 6..50
	#Check only email name
	#validates_format_of :company_email_name, :with => /^[A-Z0-9_\.%\+\-]+/i, :message => I18n.t('error_messages.email_invalid', :default => I18n.t('models.employee.should_look_like_email'))
	validates_format_of :company_email, :with => Authlogic::Regex.email, :message => I18n.t('error_messages.email_invalid', :default => I18n.t('models.employee.should_look_like_email'))
	validates_uniqueness_of :company_email, :case_sensitive => false
	#validates_length_of :ondeego_phone, :in => 7..25
	validates_uniqueness_of :user_id, :scope => [:company_id], :message => I18n.t('models.employee.already_been_added')
	# AASM
	include AASM
	aasm_column :status
	aasm_initial_state :pending
	aasm_state :pending
	aasm_state :active
	aasm_state :rejected

	aasm_event :activate do
		transitions :to => :active, :from => [:pending, :rejected]
	end

	aasm_event :reject do
		transitions :to => :rejected, :from => [:pending, :active]
	end

	by_whatever

# 20130407
#  mount_uploader :bulk_csv_file, EmployeeCSVUploader

	named_scope :by_status, lambda {|status|
		status.blank? ? {} : {:conditions => {:status => status}}
	}
	named_scope :pending, :conditions => {:status => Employee::Status::PENDING}
	named_scope :active, :conditions => {:status => Employee::Status::ACTIVE}
	named_scope :rejected, :conditions => {:status => Employee::Status::REJECTED}

	named_scope :sogo_connected, :conditions => {:is_sogo_connect => 1}

	named_scope :by_contacts, lambda {|user|
		user.blank? ? {} : {:conditions => ["company_id IN(?) and user_id != ? and status = ?", user.employees.map(&:company_id), user.id, Employee::Status::ACTIVE]}
	}

	named_scope :by_all_contacts, lambda {|user|
		user.blank? ? {} : {:conditions => ["company_id IN(?) and user_id != ?", user.employees.map(&:company_id), user.id]}
	}

	named_scope :by_search, lambda {|params|
		params.blank? ? {} : {:conditions => ["users.firstname LIKE ? or users.lastname LIKE ? or users.login LIKE ? or users.email LIKE ?", "%#{params}%", "%#{params}%", "%#{params}%", "%#{params}%"], :include => :user }
	}

	named_scope :by_accepted_published_employees, lambda{|user|
		user.blank? ? {} : {:conditions => ["company_id IN(?) and user_id != ? and status = ? and (published_at IS NULL or published_at >= ?)", user.companies.map(&:id), user.id, Employee::Status::ACTIVE, Time.now.utc - 7.days]}
	}

	named_scope :by_application_id, lambda {|application_id| application_id.blank? ? {} : {:conditions => ["employee_applications.application_id = ?", application_id], :joins => [:employee_applications]} 
	}
	named_scope :by_approved_application_id, lambda {|application_id| application_id.blank? ? {} : {:conditions => ["employee_applications.application_id = ? AND employee_applications.status = ?", application_id, EmployeeApplication::Status::APPROVED], :joins => [:employee_applications]} 
	}

	#before_validation :prepare_company_email
	after_validation :prepare_right_error_messages
	after_validation :prepare_need_update_flags
	#after_validation :crypted_company_email_password
	#after_create  :create_mobile_tribe_calendar_and_mail, :if => :create_service_for_owner 
	before_save :reset_perishable_token
	before_destroy :delete_sogo_account
	before_destroy :check_admin,                          :unless => :delete_company
	before_destroy :delete_ondeego_employee,              :unless => :delete_company
	#before_destroy :delete_mobile_tribe_calendar_and_mail
	before_destroy :delete_employee_with_service, :if => :multi_tenant
	#after_create  :create_mobile_tribe_calendar_and_mail, :if => :owner? 
	#before_destroy :delete_not_logged_user
	before_update :update_ondeego_employee
	before_update :update_sogo_account, :if => :need_sogo_update?
	before_update :update_employee_with_service, :if => :multi_tenant
	#after_save :reset_password_changed

	#after_destroy :audit_destroy

	attr_accessor :company_email_name, :send_invitation, :delete_company,:need_mobile_tribe_attr_update

	def multi_tenant
		if property(:is_multi_tenant)
			return true
		else
			return false
		end
	end

	def prepare_need_update_flags
		u = Employee.find_by_id(self.id)
			unless u.blank?
				self.need_mobile_tribe_attr_update = %w{company_email oauth_secret ondeego_user_id job_title phone status company_id}.any? do |f|
				u.send(f.to_sym) != self.send(f.to_sym)
			end 
		end
	end

	def create_service_for_owner
		if property(:is_multi_tenant)
			if owner?
				return true
			else
				return false
			end
		end
	end

	def owner?
		if property(:multi_tenant)
		end
	end

	def self.create_employee_by_company params
		success = false
		@user = User.new(params[:user])
		#@user.validates_uniqueness_of :company_email, :case_sensitive => false
		# new user will be created if user_with_same_email. by jhlee on 20120621
		#user_with_same_email = User.find_by_email(params[:user][:email])
		#unless user_with_same_email.blank?
			#@employee = user_with_same_email.employees.build(params[:employee])
			#success = @employee.save
		#else

			@employee = @user.employees.build(params[:employee])

			@user.password = @user.password_confirmation = Authlogic::Random.friendly_token[0..10]
			@user.mobile_tribe_create = true
# jhlee on 20130415
			if params[:user][:make_active].to_i==1
				@user.active = true
				@user.company_pending = 0
			else
				@user.active = false
				@user.company_pending = 1
			end
			@company = Company.find(params[:employee][:company_id])
			if @company.privacy == 1
				@user.privacy = 1
			end
# end of edit
			success = @user.valid? && @employee.valid?
			success = @user.save if success
			user_email = true
		#end

# jhlee on 20130415
			#if params[:employee][:status] == "active"
				#@employee.send(:create_employee_with_service)
			#end
# end of edit

		[success, @user, @employee]
	end

# jhlee on 20130416
	def self.activate_employees company, ids
		unless ids.blank?
					logger.info("ids........#{ids}")
			employees = company.employees.all(:conditions => ["id IN(?)", ids])
			employees.each do |employee|
				employee.status = "active"
				employee.save
				#employee.send(:create_employee_with_service)
				user = User.find_last_by_id(employee.user_id)
				user.active = true
				user.company_pending = 0
				user.save
			end
		end
	end
#end of edit

	def self.invite_employees company, ids
		unless ids.blank?
			employees = company.employees.all(:conditions => ["id IN(?)", ids])
			employees.each do |employee|
				employee.deliver_invite!
			end
		end
	end

	def self.destroy_employees(company, ids)
		not_destroy_employee = nil
			unless ids.blank?
				employees = company.employees.all(:conditions => ["id IN(?)", ids])
				employees.each do |employee|
					user = User.find_last_by_id(employee.user_id)
					logger.info("active........#{user.active.class}")
					logger.info("pending........#{user.company_pending.class}")
					if user.active == false && user.company_pending == 1
						logger.info("22222222222222222222user")
						not_destroy_employee = employee unless user.destroy
					else
						not_destroy_employee = employee unless user.destroy
					end
				end
			end
		not_destroy_employee
	end

	def self.add_company_email_domain(email_name)
		email_name.to_s + "@#{property(:sogo_email_domain)}"
	end

	def self.unique_email_name(not_unique_email)
		email_name, domain = not_unique_email.split("@")
		emails = Employee.all(:order => "company_email asc", :conditions => ["company_email like ?", "#{email_name}%@#{domain}"]).map(&:company_email)

		emails_names = emails.map{|e| e.split("@")[0]}
		uniq_email_name = emails_names.last + "1"
		(1..1000).each do |index|
			name = email_name + index.to_s
			uniq_email_name = name and break unless emails_names.include?(name)
		end
		uniq_email_name
	end

	def self.unique_email(not_unique_email)
		email_name, domain = not_unique_email.split("@")
		emails = Employee.all(:order => "company_email asc", :conditions => ["company_email like ?", "#{email_name}%@#{domain}"]).map(&:company_email)
		emails_names = emails.map{|e| e.split("@")[0]}
		uniq_email_name = emails_names.last + "1"
		(1..1000).each do |index|
			name = email_name + index.to_s
			uniq_email_name = name and break unless emails_names.include?(name)
		end
		uniq_email_name + '@' + domain
		
	end

	def owner_employee? company = self.company
		self.user_id == company.user_id
	end

	def accept
		self.send(:create_employee_with_service)
		#self.send(:create_mobile_tribe_calendar_and_mail) 
		#logger.info("creating sogo and c")
		#self.activate! if self.sogo_connect! != false
		self.activate!
	end

	def reject
		if self.owner_employee?
			self.errors.add_to_base(I18n.t("controllers.you_could_not_reject_this_invite"))
		else
			dup_employee_for_update = self.dup
			ondeego_delete = self.send(:delete_ondeego_employee)
			if ondeego_delete
				dup_employee_for_update.ondeego_user_id = nil
				dup_employee_for_update.is_ondeego_connect = 0
				dup_employee_for_update.oauth_token = nil
				dup_employee_for_update.oauth_secret = nil
				dup_employee_for_update.company_email = nil
			end
			#mobile_tribe_delete = self.send(:delete_mobile_tribe_calendar_and_mail)
			#dup_employee_for_update.is_mobiletribe_connect = 0 if mobile_tribe_delete

			#sogo_delete = self.send(:delete_sogo_account)
			#dup_employee_for_update.is_sogo_connect = 0 if sogo_delete

			#Save dup employee with updating all change ondeego, sogo or mt properties without removing errors
			dup_employee_for_update.save(false)
			success = self.reject! if ondeego_delete
			self.send(:unassign_department_application_from_employee) if success
			self.user.destroy if success
			success
			#self.reject! if ondeego_delete && mobile_tribe_delete && sogo_delete
		end
	end

	def ondeego_connect!(ondeego_user_id)
		begin
			token = Services::OnDeego::OauthClient.new.get_access_token(ondeego_user_id)
			self.ondeego_user_id = ondeego_user_id
			self.is_ondeego_connect = 1
			self.oauth_token = token.token
			self.oauth_secret = token.secret
			self.save(false)
		rescue Services::OnDeego::Errors::OnDeegoError => e
			self.errors.add_to_base("#{I18n.t('models.company.appcentrall_error')} #{e.to_s}")
			return false
		end
		return true
	end

	def fail_ondeego_connect!
		#reset_perishable_token
		#self.save
	end

	def sogo_connect!
		logger.info("sogo connecting...............................................")
		unless self.sogo_connect?
			success = self.send(:create_sogo_account)
			#if success && self.user.employees.first(:conditions => ["is_mobiletribe_connect = 1"]).blank?
			#success = self.send(:create_mobile_tribe_calendar_and_mail)
			#end
			success && self.errors.blank?
		end
	end

	def ondeego_connect?
		self.is_ondeego_connect == 1 && !self.oauth_token.blank? && !self.oauth_secret.blank?
	end

	def sogo_connect?
		self.is_sogo_connect == 1 && !self.company_email.blank?
	end

	def mobile_tribe_user?
		self.sogo_connect? && self.user.mobile_tribe_user? && self.is_mobiletribe_connect == 1
	end

	def mtribe_user?
		self.user.mobile_tribe_user? && self.is_mobiletribe_connect == 1
	end

	def pending?
		self.status == Status::PENDING
	end

	def active?
		self.status == Status::ACTIVE
	end

	def rejected?
		self.status == Status::REJECTED
	end

	def deliver_invite!
		if self.pending?
			self.reset_invitation_token!
			Notifier.deliver_invite!(self)
		end
	end

	def company_email_name
		@company_email_name ||= self.company_email.blank? ? "" : self.company_email.split("@")[0]
	end

	def department_name
		self.department.blank? ? "" : self.department.name
	end

	def owner?
		company = Company.find(self.company_id)
		company.user_id == self.user_id
	end


	def need_ondeego_update?
		e = Employee.find_by_id(self.id)
		e.job_title != self.job_title || e.phone.to_s != self.phone.to_s
	end


	def need_sogo_update?
		e = Employee.find_by_id(self.id)
		e.company_email != self.company_email
	end

	def ondeego_job_title
		self.job_title.to_s.blank? ? "Employee" : self.job_title.to_s
	end

	def reset_invitation_token!
		self.invitation_token = Authlogic::Random.friendly_token
		self.save(false)
	end

	def published!
		if self.active? && self.published_at.blank?
			self.published_at = Time.now.utc
			return self.save(false)
		else
			return false
		end
	end

	def email_password
		self.user.decrypted_user_password.to_s
	end

	def name
		"#{self.user.name} of #{self.company.name}"
	end

	def to_services_attrs
		{"app_central" =>  {"user_id" => self.ondeego_user_id, "is_connect" => self.is_ondeego_connect, "oauth_secret" => self.oauth_secret, "oauth_token" => self.oauth_token}, "sogo" => {"is_connect" => self.is_sogo_connect, "email" => self.company_email}, "mobile_tribe" => {"is_connect" => self.is_mobiletribe_connect} }
	end
	
	def can_request_application?(application)
		!self.employee_applications.find_by_application_id(application.id).present? if application.present?
	end

	def create_c2call_service
		success = true
		if property(:use_mobile_tribe) && self.is_mobiletribe_connect == 1
			begin
				fields = {
					"portalUserId" => self.company_email.to_s,
					"password" => self.email_password,
					"crypted_password" => self.email_password,
				}

				ippbx = Ippbx.find_by_admin_type_and_employee_id("user", self.id)
				if !ippbx.blank?
					public_number = ippbx.public_number
					fields["portalMetadata"] = htmlsafe(public_number)
				end
				logger.info(fields)
				#Services::MobileTribe::Connector.new.create_c2call(self.user.mobile_tribe_login, self.user.mobile_tribe_password,fields)
				#TODO Remove connection if error happen after this
				#Employee.update_all("is_mobile_tribe_connect = 0", "id = #{self.id}")

			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				success = false
			end
		end
		return success
	end

	def unique_email_for_employee not_unique_email
		email_name, domain = not_unique_email.split("@")
		emails = Employee.all(:order => "company_email asc", :conditions => ["company_email like ?", "#{email_name}%@#{domain}"]).map(&:company_email)
		if !emails.blank?
			emails_names = emails.map{|e| e.split("@")[0]}
			uniq_email_name = emails_names.last + "1"
			(1..1000).each do |index|
				name = email_name + index.to_s
				uniq_email_name = name and break unless emails_names.include?(name)
			end
			uniq_email_name + '@' + domain
		else
		not_unique_email
		end
	end

  #TODO: Remove this later
  #  def require_password?
  #    new_record? || (!self.email_password.blank? || !self.email_password_confirmation.blank?) || ( !new_record? && self.company_email_password.blank?)
  #  end

	protected

	def send_update_ondeego_employee user = self.user
		ondeego_client = Services::OnDeego::OauthClient.new(:oauth_token => self.oauth_token, :oauth_secret => self.oauth_secret)
		fields = {"userId" => self.ondeego_user_id.to_s,
		"firstName" => user.firstname,
		"lastName" => user.lastname,
		"address" => user.address,
		"city" => user.city,
		"state" => user.state,
		"countryISOCode" => user.iso_country_code,
		"jobTitle" => self.ondeego_job_title,
		"phone" => self.phone.to_s}

		fields = fields.delete_if do |key, value|
		["firstName", "lastName", "jobTitle", "address", "city", "state", "countryISOCode", "phone"].include?(key) &&
		value.blank?
		end

		ondeego_client.update_employee(fields)
	end

	private

	def prepare_company_email
		self.company_email = Employee.add_company_email_domain(self.company_email_name)
	end

	def prepare_right_error_messages
		company_errors = self.errors.on(:company_email)
		unless company_errors.blank?
			company_errors.to_a.each do |error|
				self.errors.add(:company_email_name, error)
		end
		self.filter_error_messages(["company_email"])
		end
	end

	def reset_perishable_token
		self.perishable_token = Authlogic::Random.friendly_token
	end

  #TODO: Remove this
  # Resets the password to a random friendly token.
  #  def reset_password_changed
  #    friendly_token = Authlogic::Random.friendly_token
  #    self.email_password = friendly_token
  #    self.email_password_confirmation = friendly_token
  #  end

  #TODO: Remove this
  #  def crypted_company_email_password
  #    self.company_email_password = self.user.user_password unless self.user.blank?
  ##    if require_password? && !self.email_password.blank?
  ##      #self.company_email_password = Digest::MD5.hexdigest(self.email_password.to_s)
  ##      self.company_email_password = self.email_password.to_s
  ##    end
  #  end

	def check_admin
		if self.owner_employee?
			self.errors.add_to_base("#{I18n.t('models.employee.not_allow_delete_owner_employee')}")
			return false
		end
		return true
	end

	def delete_not_logged_user
		User.delete(self.user.id) if self.pending? && !self.user.login_once? && self.user.employees.size <= 1
	end

	def delete_ondeego_employee
		success = true
		if property(:use_ondeego) && self.ondeego_connect?
			begin
				Services::OnDeego::OauthClient.new(:oauth_token => self.oauth_token,
				:oauth_secret => self.oauth_secret
				).delete_employee("userId" => self.ondeego_user_id.to_s)
				#TODO Remove connection if error happen after this
				#Employee.update_all("ondeego_user_id = NULL, is_ondeego_connect = 0, oauth_token = NULL, oauth_secret = NULL", "id = #{self.id}")
			rescue Services::OnDeego::Errors::OnDeegoError => e
				Employee.logger.info "Employee OnDeego error #{e.inspect}"
				self.errors.add_to_base("#{I18n.t('models.company.appcentrall_error')} #{e.to_s}")
				#success = false
			end
		end
		return success
	end

	def update_ondeego_employee
		success = true
		if property(:use_ondeego) && self.ondeego_connect? && self.need_ondeego_update?
			begin
				self.send_update_ondeego_employee
			rescue Services::OnDeego::Errors::OnDeegoError => e
				self.errors.add_to_base("#{I18n.t('models.company.appcentrall_error')} #{e.to_s}")
				success = false
			end
		end
		return success
	end

	def create_sogo_account
		success = true
		if property(:use_sogo) && !self.sogo_connect?
			begin
				Services::Sogo::Wrapper.new.create_user(:email => self.user.service_email, #:email => self.company_email
				:password => self.email_password,
				:crypted_password => Tools::MysqlEncrypt.mysql_encrypt(self.email_password),
				:full_name => self.user.name)
				self.update_attribute("is_sogo_connect", "1")
			rescue Services::Sogo::Errors::OnWrapperError => e
				self.errors.add_to_base("#{I18n.t('models.company.sogo_error')} #{e.to_s}")
				#self.send(:delete_employee_with_service)
				#self.update_attribute("status","pending")
				success = false
			end
		end
		return success
	end

	def update_sogo_account
		success = true
		if property(:use_sogo)
			if self.sogo_connect?
				begin
					Services::Sogo::Wrapper.new.update_user(:email => self.user.service_email, #self.company_email,
					:password => self.email_password,
					:crypted_password => Tools::MysqlEncrypt.mysql_encrypt(self.email_password),
					:full_name => self.user.name)
				rescue Services::Sogo::Errors::OnWrapperError => e
					self.errors.add_to_base("#{I18n.t('models.company.sogo_error')} #{e.to_s}")
					return false
				end
			end
			#update MT calendar and mail
			if property(:use_mobile_tribe)
				success = self.send(:create_mobile_tribe_calendar_and_mail) if self.mobile_tribe_user?
			end
		end
		return success
	end

	def delete_sogo_account
		success = true
		if property(:use_sogo) && self.sogo_connect?
			begin
				Services::Sogo::Wrapper.new.delete_user(:email => self.user.service_email) #:email => self.company_email
				#TODO Remove connection if error happen after this
				# Employee.update_all("is_sogo_connect = 0", "id = #{self.id}")
			rescue Services::Sogo::Errors::OnWrapperError => e
				self.errors.add_to_base("#{I18n.t('models.company.sogo_error')} #{e.to_s}")
				#success = false
			end
		end
		return success
	end

	def create_mobile_tribe_calendar_and_mail
		success = true
		if property(:use_mobile_tribe) && self.user.mobile_tribe_user?
			begin
				Services::MobileTribe::Connector.new.create_calendar_and_mail(self.user.mobile_tribe_login, self.user.mobile_tribe_password,
				"portalUserId" => self.company_email.to_s,
				"password" => self.email_password,
				"crypted_password" => self.email_password)
				self.update_attribute("is_mobiletribe_connect", "1")
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				self.send(:delete_employee_with_service)
				self.update_attribute("status","pending")
				self.send(rollback_changes)
				#success = false
			end
		end
		return success
	end

	def delete_mobile_tribe_calendar_and_mail
		logger.info("delete employee calender")
		success = true
		if property(:use_mobile_tribe) && self.mtribe_user?
			begin
				Services::MobileTribe::Connector.new.remove_calendar_and_mail(self.user.mobile_tribe_login, self.user.mobile_tribe_password)
				#TODO Remove connection if error happen after this
				#Employee.update_all("is_mobiletribe_connect = 0", "id = #{self.id}")
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				#success = false
			end
		end
		return success
	end

	def create_employee_with_service
		logger.info "create_employee_with_service"
		if(property(:use_mobile_tribe))
			begin
				user = User.find_by_id(self.user_id)
				if self.company_email.blank?
					employee_company_email = self.user.login + "@" + property(:sogo_email_domain)
					employee_company_email = self.unique_email_for_employee(employee_company_email)
					self.update_attribute("company_email",employee_company_email)
					company_email_blank = true
				end
				#ippbx_enabled = "0" 
				#public_number = ""
				#ippbx = Ippbx.find_by_admin_type_and_employee_id("user", self.id)
				#if !ippbx.blank?
				#	ippbx_enabled = "1" 
				#	public_number = ippbx.public_number
				#end
				#emp = Employee.find_by_user_id(user.id)
				mobile_tribe = Services::MobileTribe::Connector.new
				fields = {
					"companyId" => htmlsafe(self.company_id.to_s),
					"userId" => htmlsafe(self.user_id.to_s),
					"employeeId" => htmlsafe(self.id.to_s),
					"firstName" => htmlsafe(user.firstname.to_s),
					"lastName" => htmlsafe(user.lastname.to_s),
					"status" => htmlsafe(Employee::Status::ACTIVE),
					#"phone" => htmlsafe(user.phone.to_s),
					"companyEmail" => htmlsafe(self.company_email.to_s),
					"officePhone" => htmlsafe(user.phone.to_s),
					"jobTitle" => htmlsafe(self.job_title.to_s)
				}

				if (!self.department_id.blank?)
					departments = {"departmentId" => htmlsafe("-"+ self.department_id.to_s)}
					fields.merge(departments)
				end

				#if ippbx_enabled == "1"
				#	fields["isIppbxEnabled"] = htmlsafe(ippbx_enabled)
				#	fields["publicNumber"] =  htmlsafe(public_number)
				#end

				mobile_tribe.create_employee(fields)
				self.update_attribute("is_mobiletribe_connect", "1")
				self.sogo_connect!
				#self.created!
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				#self.delete_employee_with_service
				db_fields = {:status => Employee::Status::PENDING}
				if company_email_blank
				  db_fields[:company_email] = ""
				end
				self.update_attributes(db_fields)
				self.send(rollback_changes)
				#self.fail!
				#self.notCreated!
				return false
			end
		end
	end
  
  
	def update_employee_with_service
		if(property(:use_mobile_tribe))
			user = User.find_by_id(self.user_id)
			mobile_tribe = Services::MobileTribe::Connector.new
			if (self.status == Employee::Status::ACTIVE) && self.is_mobiletribe_connect == 1
				begin
					#ippbx_enabled = "0"
					#public_number=""
					#ippbx = Ippbx.find_by_admin_type_and_employee_id("user", emp.id)
					#if !ippbx.blank?
					#	ippbx_enabled = "1" 
					#	public_number = ippbx.public_number
					#end

					fields = {
						"userId" => htmlsafe(user.id.to_s),
						"companyId" => htmlsafe(self.company_id.to_s),
						"employeeId" => htmlsafe(self.id.to_s),
						"firstName" => htmlsafe(user.firstname.to_s),
						"lastName" => htmlsafe(user.lastname.to_s),
						"status" => htmlsafe(self.status.to_s),
						"officePhone" => htmlsafe(self.phone.to_s),
						"jobTitle" => htmlsafe(self.job_title.to_s),
						"companyEmail" => htmlsafe(self.company_email.to_s)
					}

					unless self.department_id.blank?
						fields["departmentId"] = htmlsafe("-"+self.department_id.to_s)
					else
						fields["departmentId"] =""
					end      

					#if ippbx_enabled == "1"
					#	decrypted_password = user.user_password.blank? ? "" : Tools::AESCrypt.new.decrypt(user.user_password).to_s
					#	fields["isIppbxEnabled"] = htmlsafe(ippbx_enabled)
					#	fields["publicNumber"] =  htmlsafe(public_number)
					#	fields["password"]     =  htmlsafe(decrypted_password.to_s)
					
				        #end

					mobile_tribe.update_employee(fields) if self.need_mobile_tribe_attr_update
				rescue Services::MobileTribe::Errors::MobileTribeError => e
					self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
					return false
				end
			end
		end
	end

	def delete_employee_with_service
		logger.info("deleting Employe>>>>>>>>>>>>>>>>>>>")
		if (self.status != "pending") && self.is_mobiletribe_connect == 1
			begin
				mobile_tribe = Services::MobileTribe::Connector.new
				fields = {"companyId" => htmlsafe(self.company_id.to_s), "employeeId" => htmlsafe(self.id.to_s)}
				unless self.department_id.blank?
					departmentField = {"departmentId" => htmlsafe("-" + self.department_id.to_s)}
					fields.merge(departmentField)
				end
				mobile_tribe.destroy_employee(fields)
				logger.info("1111111")
				#unless self.company.user_id == self.user_id
				#        logger.info("delte user emp......")
			        #		user = User.find_by_id(self.user_id)
				#	user.destroy
				#end
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				self.send(rollback_changes)
				#return false
			end
		end
	end

	def assign_department_application_to_employee
		self.department.department_applications.each do |d_app|
		self.employee_applications.create(:application_id => d_app.application_id)
		end unless self.department.blank?
		end

	def unassign_department_application_from_employee(dep = self.department)
		unless dep.blank?
			ids = dep.department_applications.map(&:application_id)
			EmployeeApplication.destroy_all(["employee_id = ? AND application_id IN(?)", self.id, ids]) unless ids.empty?
		end
	end

	def check_department_application
		if self.active?
			self.send(:unassign_department_application_from_employee, Department.find_by_id(self.department_id_was))
			self.send(:assign_department_application_to_employee)
		end
	end


	def rollback_changes
		raise ActiveRecord::Rollback, "Something went wrong with MTP, check the logs!"
	end


	def htmlsafe(str)
		@escaped = URI::escape(str.to_s)
		return @escaped
	end
#  def audit_destroy
#    attr = {}
#    attr[:status] = self.errors.empty? ? Audit::Statuses::SUCCESS : Audit::Statuses::FAILED
#    attr[:name] = "#{self.user.name} from #{self.company.name}"
#    attr[:description] = {:messages => self.errors.full_messages,
#                          :attributes => self.to_services_attrs.merge({
#                            "created_at" => self.created_at.to_s,
#                            "company_id" => self.company_id,
#                            "user_id" => self.user_id})} if attr[:status] == Audit::Statuses::FAILED
#    self.create_audit(attr)
#  end

end

#UPDATE employees SET company_email=(REPLACE(company_email,'STR1','STR2'));
#UPDATE employees e join users u on e.user_id=u.id SET e.company_email=(concat(u.login,'@STR1'));
#UPDATE employees SET company_email=(REPLACE(company_email,' ',''));

#update users set is_mobiletribe_connect=0;
#update companies set is_mobiletribe_connect=0;
#update departments set is_mobiletribe_connect=0;
#update employees set is_mobiletribe_connect=0;
#update friendships set is_mobiletribe_connect=0;

#update employees set is_sogo_connect=0;