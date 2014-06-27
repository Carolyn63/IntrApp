class Company < ActiveRecord::Base

  attr_reader :employee

  cattr_reader :per_page
  @@per_page = 25

  module Privacy
    PUBLIC = 0
    PRIVATE = 1

    LIST = [
      [I18n.t("models.company.public"), PUBLIC],
      [I18n.t("models.company.private"), PRIVATE]
    ]
    TO_LIST = {
      PUBLIC => I18n.t("models.company.public"),
      PRIVATE => I18n.t("models.company.private")
    }
  end

  module Search
    #SEARCH_FIELDS = %w{name address phone company_type description industry}
    SEARCH_FIELDS = %w{name country industry}
    SEARCH_BY = [
      [I18n.t("models.company.all"), ""],
      [I18n.t("models.company.name"), "name"],
      [I18n.t("models.company.country"), "country"],
      #[I18n.t("models.company.phone"), "phone"],
      #[I18n.t("models.company.company_type"), "company_type"],
      #[I18n.t("models.company.description"), "description"],
      [I18n.t("models.company.industry_focus"), "industry"]
    ]

    #SORT_FIELDS = %w{name address phone company_type industry}
    SORT_FIELDS = %w{name country industry}
    SORT_BY = [
      [I18n.t("models.company.name"), "name"],
      [I18n.t("models.company.country"), "country"],
      #[I18n.t("models.company.phone"), "phone"],
      #[I18n.t("models.company.company_type"), "company_type"],
      [I18n.t("models.company.industry_focus"), "industry"]
    ]
  end

  act_as_services_delete_audit :with_audit_association => :employees, :additional_audited_columns => %w{created_at user_id id name industry}

  has_attached_file :logo,
  :styles => { :medium => "70x70", :thumb => "55x55", :big => "187x187"},
  :path => ":rails_root/public/system/logos/:id/:style/:filename",
  :url => "/system/logos/:id/:style/:filename",
  :default_url => "/system/logos/:style/missing.png"

  before_post_process :lowercase_file_extenstion

  belongs_to :admin, :class_name => "User", :foreign_key => "user_id"
  #Used delete_all for delete employees without call ondeego delete api, OnDeego remove employees of company self
  has_many :employees
  has_one  :ippbx
  has_one  :cloudstorage
  #has_many :hosted_services, :dependent => :destroy
  has_one  :domain, :dependent => :destroy, :foreign_key => "company_id"
  has_many :active_employees, :class_name => "Employee", :conditions => {:status => Employee::Status::ACTIVE},
  :limit => 10000
  has_many :user_employees, :class_name => "User",
  :through => :employees, :source => :user, :order => "email ASC"
  has_many :active_user_employees, :class_name => "User",
  :through => :employees, :source => :user, :order => "email ASC",
  :conditions => ["employees.status = ?", Employee::Status::ACTIVE]

  has_one  :admin_employee, :class_name => "Employee", :foreign_key => "company_id",
  :conditions => ['employees.user_id = #{self.user_id}']
  has_many :departments, :dependent => :destroy
  
  has_many :companifications, :dependent => :destroy
  has_many :applications, :through => :companifications
  has_many :employee_application_requests, :source => :employee_applications,
           :through => :employees, :conditions =>  ["employee_applications.status = ?", EmployeeApplication::Status::PENDING]
           



  #has_one :audit, :as => :auditable, :order => "created_at DESC"

  accepts_nested_attributes_for :departments, :allow_destroy => true

  validates_presence_of :name, :privacy, :user_id
  #validates_length_of :phone, :in => 7..25, :allow_blank => true
  #validates_format_of :phone, :with => /^[(0-9)+]{7,25}$/, :message => I18n.t("models.company.should_be_format"), :allow_blank => true
  validates_length_of :industry, :in => 1..50, :allow_blank => true
  validates_length_of :address, :in => 1..50, :allow_blank => true
  validates_length_of :city, :in => 1..50, :allow_blank => true
  validates_length_of :name, :in => 1..50
  validates_attachment_content_type :logo, :content_type => ["image/gif","image/jpeg","image/png"]
  validates_attachment_size       :logo, :less_than => 5.megabytes
  attr_accessor :need_mobile_tribe_attr_update

  by_whatever

  named_scope :public, :conditions => {:privacy => Company::Privacy::PUBLIC}
  named_scope :private, :conditions => {:privacy => Company::Privacy::PRIVATE}

  named_scope :by_public_and_employers, lambda { |user|
  user.blank? ? {} : {:conditions => ["companies.privacy = ? or
  (companies.privacy = ? and companies.id IN(?))",
  Company::Privacy::PUBLIC, Company::Privacy::PRIVATE, user.active_employees.map(&:company_id)]
  }
  }

  named_scope :without_own_companies, lambda {|user_id|
  user_id.blank? ? {} : {:conditions => ["companies.user_id != ?", user_id]}
  }

  named_scope :active_and_pending_employers, lambda {
  {:conditions => ["employees.status = ? or employees.status = ?", Employee::Status::ACTIVE,
  Employee::Status::PENDING], :include => [:employees]}
  }

  named_scope :active_employers, lambda {
  {:conditions => ["employees.status = ?", Employee::Status::ACTIVE], :include => [:employees]}
  }

  named_scope :by_employee_status, lambda {|status|
  status.blank? ? {} : {:conditions => ["employees.status = ?", status], :include => [:employees]}
  }

  named_scope :by_search, lambda {|params|
  params.blank? ? {} : {:conditions => ["name LIKE ? or country LIKE ? or industry LIKE ?", "%#{params}%", "%#{params}%", "%#{params}%"]}
  }
  
  named_scope :by_country, lambda {|country|
  country.blank? ? {} : {:conditions => ["country =? ", country]}
  }
  named_scope :by_country, lambda {|country|
  country.blank? ? {} : {:conditions => ["country LIKE ? ", "#{country}%"]}
  }
  named_scope :by_industry, lambda {|industry|
  industry.blank? ? {} : {:conditions => ["industry LIKE? ", "#{industry}%"]}
                                   }
   named_scope :by_first_letter, lambda {|letter|
  letter.blank? ? {} : {:conditions => ["lower(name) LIKE ? ", "#{letter}%"]}
  }
  named_scope :ordered, :order => :'name asc'
    
  after_validation :prepare_need_update_flags
  after_create :create_company_with_service, :if => :multi_tenant
  before_save :reset_perishable_token
  before_update :update_company_with_service, :if => :multi_tenant
  after_update :update_ondeego_company
  before_destroy :delete_company_with_service, :if => :multi_tenant
  #before_destroy :delete_employees
  before_destroy :delete_ondeego_company
  
  
  #after_destroy :audit_destroy
  def multi_tenant
   if property(:is_multi_tenant)
    return true
   else
    return false
   end
  end
  
  def after_validation
    # Skip errors that won't be useful to the end user
    self.filter_error_messages(["employees"])
  end
  
  def to_s; name; end

  def self.search_or_filter_companies user, params = {}
    params[:sort_by] = !params[:sort_by].blank? && Company::Search::SORT_FIELDS.include?(params[:sort_by]) ? params[:sort_by] : Company::Search::SORT_FIELDS[0]
    params[:alphabet] = params[:alphabet].to_s.first.underscore
    if params[:search].blank?
    companies = Company.by_public_and_employers(user).by_first_letter(params[:alphabet]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
    else
      if params[:search_by].blank?
        companies = Company.by_public_and_employers(user).by_search(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
      elsif params[:search_by] == "name"
        companies = Company.by_public_and_employers(user).by_first_letter(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
      elsif params[:search_by] == "country"
        companies = Company.by_public_and_employers(user).by_country(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
      elsif params[:search_by] == "industry"
        companies = Company.by_public_and_employers(user).by_industry(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
      end
    end
    companies
  end

  def employee user
    self.employees.find_by_user_id( user.id )
  end

  def employee_pending? user
    e = self.employees.find_by_user_id( user.id )
    e.blank? ? false : e.pending?
  end
  
  def active_employees_per_application(application)
    application.blank? ? [] : self.employees.by_approved_application_id(application.id).all
  end

  def departments_per_application(application)
    application.blank? ? [] : self.departments.by_application_id(application.id).all
  end

  def owner? user
    user == self.admin
  end

  def ondeego_connect!(ondeego_company_id)
    self.update_attributes(:ondeego_company_id => ondeego_company_id, :is_ondeego_connect => 1)
  end

  def ondeego_connect?
    self.is_ondeego_connect == 1
  end

  def fail_ondeego_connect!
    #reset_perishable_token
    #self.save
  end

  def need_ondeego_update?
    c = Company.find_by_id(self.id)
    !self.logo.queued_for_write.blank?
  end
  
  def mobiletribe_connect!
    self.update_attribute("is_mobiletribe_connect", 1)
  end
  
  def mobiletribe_connect?
    self.is_mobiletribe_connect == 1
  end

  def full_address
    arr = []
    arr << self.address unless self.address.blank?
    arr << self.city unless self.city.blank?
    arr.join(",")
  end

  def profile_complete
    profile_fields = [ :name, :address, :city, :phone, :company_type, :industry, :description, :size, :team,
      :logo_file_name, :country_phone_code, :website, :twitter, :facebook, :linkedin, :country
    ]

    weight = 100.to_f/profile_fields.size.to_f
    percentage_complete = 0

    profile_fields.each do |profile_field|
      unless self[profile_field].blank?
      percentage_complete += weight
      end
    end
    percentage_complete.to_i <= 99 ? percentage_complete.to_i + 1 : percentage_complete.to_i
  end
  
  def has_approved_application?(application)
    self.companifications.approved.find_by_application_id(application.id).present? or  self.companifications.paid.find_by_application_id(application.id).present? or self.companifications.trial.find_by_application_id(application.id).present?if application.present?
  end

  def can_request_application?(application)
    !self.companifications.find_by_application_id(application.id).present? if application.present?
  end

  def to_services_attrs
    {"app_central" =>  {"company_id" => self.ondeego_company_id, "is_connect" => self.is_ondeego_connect}}
  end
  
	def use_ippbx?
		success = false
		if property(:use_ippbx)
			success = true
		end
		return success
	end

	def subscribed_all_services? owner
		success = true
		company_services = CompanyService.find_all_by_user_id(owner.id)
		services = Service.find_all_by_active(1)
		logger.info(services.size)
		logger.info(company_services.size)

		i = 0
		if company_services.size >= services.size
			company_services.each do |company_service|
			grace_period = DateTime.parse("2012-05-05 01:09:05") + 7.days
			unless(company_service.paid == 0 && company_service.subscription_type == "subscr_signup" ) || company_service.paid == 1  || (company_service.subscription_type == "subscr_cancel" and graceperiod > Time.now)
			#unless  service.paid == 1 or service.subscription_type == "subscr_signup"
				logger.info "Company False............"
				i+=1
				end
			end
		else
			i+=1
		end

		if i>0
			success = false
		end
		
		return success
	end

  private

  def lowercase_file_extenstion
    extension = File.extname(self.logo.original_filename).gsub(/^\.+/, '')
    filename = self.logo.original_filename.gsub(/\.#{extension}$/, '')
    self.logo.instance_write(:file_name, "#{filename}.#{extension.downcase}")
  end

  def reset_perishable_token
    self.perishable_token = Authlogic::Random.friendly_token
  end
  
  def prepare_need_update_flags
    u = Company.find_by_id(self.id)
   unless self.new_record?
     self.need_mobile_tribe_attr_update =  %w{name description phone country_phone_code address city state country website facebook twitter linkedin industry privacy}.any? do |f|
                                         u.send(f.to_sym) != self.send(f.to_sym)
                                      end
   end
  end

  def delete_employees
    association_errors = []
    #self.audit ||= self.build_audit
    self.employees.each do |employee|
      employee.delete_company = true
      employee.update_attribute("is_mobiletribe_connect",0) # Not to send delete employee notification.(Delete Company will delete associated employees and departments)
      user_id = employee.user_id
	    unless employee.user_id == self.user_id
	    user = User.find_by_id(employee.user_id)
	    logger.info("delete use1111111111111")
	    user.destroy
	    unless user.errors.empty? 
	      
	      association_errors << "Error deleting Employee ##{employee.id}: #{employee.errors.full_messages.to_a.join('; ')}"
            end
	    else
	    employee.destroy
	    	    logger.info("delete emp2222222222222")
	     unless employee.errors.empty?
	       logger.info("222222222222222")
	      association_errors << "Error deleting Employee ##{employee.id}: #{employee.errors.full_messages.to_a.join('; ')}"
             end
	    end

     
      
  
      
      #    self.audit.associations_audits << employee.audit

    #
    #      success = employee.send(:delete_mobile_tribe_calendar_and_mail)
    #      success &= employee.send(:delete_sogo_account)
    #      if success
    #        employee.delete
    #      else
    #        self.errors.add_to_base(I18n.t('models.company.employee_delete_error'))
    #        return false
    #      end
    end
    if association_errors.size > 5
    self.errors.add_to_base("Error deleting of #{association_errors.size} Employees")
    else
      association_errors.each {|e| self.errors.add_to_base("#{e}") }
    end
    return true
  end

	def delete_ondeego_company
		admin = self.employees.map.find{|c| c.user_id == self.user_id}
		if property(:use_ondeego) && self.ondeego_connect? && !admin.blank? && admin.ondeego_connect?
			begin
				Services::OnDeego::OauthClient.new(
					:oauth_token => admin.oauth_token,
					:oauth_secret => admin.oauth_secret
				).delete_company("companyId" => self.ondeego_company_id.to_s)
				#Company.update_all("is_ondeego_connect = 0", "id = #{self.id}")
			rescue Services::OnDeego::Errors::OnDeegoError => e
				self.errors.add_to_base("#{I18n.t('models.company.appcentrall_error')} #{e.to_s}")
				#return false
			end
		end
	end

	def update_ondeego_company
		if property(:use_ondeego) && self.ondeego_connect? && self.need_ondeego_update?
			begin
				ondeego_client = Services::OnDeego::OauthClient.new(:oauth_token => self.admin_employee.oauth_token, :oauth_secret => self.admin_employee.oauth_secret)
				self.logo.save
				ondeego_client.update_company(
					"companyId" => self.ondeego_company_id.to_s,
					"companyLogoURL" => URI.escape(property(:app_site) + self.logo.url(:original,false).to_s),
					"numberEmployeesAllowed" => "0"
				)
			rescue Services::OnDeego::Errors::OnDeegoError => e
				RAILS_DEFAULT_LOGGER.info "Ondeego update error: #{e.to_s}"
				#self.errors.add_to_base("Ondeego error: #{e.to_s}")
				#return false
			end
		end
	end

	def create_company_with_service
		logger.info("creating company>>>>>>>>>>>>>>>>>>>")
		if(property(:use_mobile_tribe))
			empId = Employee.find_by_company_id(self.id)
			#user = User.find_by_id(empId.user_id)
			mobile_tribe = Services::MobileTribe::Connector.new
			#self.owner_create_fail = false
			begin
				fields = {
					"companyId" => htmlsafe(self.id),
					"companyName" => htmlsafe(self.name.to_s),
					"userId" => htmlsafe(self.user_id),
					"employeeId" => htmlsafe(empId.id.to_s),
					"description" => htmlsafe(self.description.to_s),
					"companyPhone" => htmlsafe(self.phone.to_s),
					"companyPhoneCountryCode" => htmlsafe(self.country_phone_code.to_s),
					"address" => htmlsafe(self.address.to_s),
					"city" => htmlsafe(self.city.to_s),
					"state" => htmlsafe(self.state.to_s),
					"country" => htmlsafe(self.country.to_s),
					"companyWebsite" => htmlsafe(self.website.to_s),
					"companyFacebook" => htmlsafe(self.facebook.to_s),
					"companyTwitter" => htmlsafe(self.twitter.to_s),
					"companyLinkedIn" => htmlsafe(self.linkedin.to_s),
					"companyIndustry" => htmlsafe(self.industry.to_s),
					"companyTeamLeaders" => htmlsafe(self.team.to_s)
				}
                                self.mobiletribe_connect!
				mobile_tribe.create_company(fields)
				self.send(:create_owner_with_service)
				#self.update_attribute("is_mobiletribe_connect", "1")
                        rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" ) 
				Employee.find_by_company_id(self.id).delete
				Company.find_by_id(self.id).delete
				self.send(rollback_changes)
				#return false
			end
		end
	end

	 #Create Employee notification for Owner.
	def create_owner_with_service
		logger.info("creating owner>>>>>>>>>>>>>>>>>>>>>>>")
		if(property(:use_mobile_tribe))
			empId = Employee.find_by_company_id(self.id)
			user = User.find_by_id(empId.user_id)
			mobile_tribe = Services::MobileTribe::Connector.new
			begin
				fields = {
					"companyId" => htmlsafe(empId.company_id.to_s),
				 "userId" => htmlsafe(empId.user_id.to_s),
				 "employeeId" => htmlsafe(empId.id.to_s),
				 "firstName" => htmlsafe(user.firstname.to_s),
				 "lastName" => htmlsafe(user.lastname.to_s),
				 "status" => htmlsafe("active"),
				 "phone" => htmlsafe(user.phone.to_s),
				 "officePhone" => htmlsafe(empId.phone.to_s),
				 "jobTitle" => htmlsafe(empId.job_title.to_s),
				 "companyEmail" => htmlsafe(empId.company_email.to_s)
				}
				if empId.department_id.blank?
					fields["departmentId"] = ""
				else
					fields["departmentId"] = htmlsafe("-"+empId.department_id.to_s)
				end
				#"departmentId" => htmlsafe("-"+empId.department_id.to_s)}
				mobile_tribe.create_employee(fields)
				empId.update_attribute("is_mobiletribe_connect", "1")
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				#self.owner_create_fail = true
				#Employee.find_by_company_id(self.id).delete
				self.delete_company_with_service
				Company.find_by_id(self.id).delete
				self.send(rollback_changes)
				return false
			end
		end
	end 
    
    #Update Company Notifications
    
	def update_company_with_service 
		if(property(:use_mobile_tribe)) && self.mobiletribe_connect?
			begin
				empId = Employee.find_by_company_id(self.id)
				mobile_tribe = Services::MobileTribe::Connector.new
				fields= {
					"companyId" => htmlsafe(self.id),
					"companyName" => htmlsafe(self.name.to_s),
					"userId" => htmlsafe(self.user_id),
					"employeeId" => htmlsafe(empId.id.to_s),
					"description" => htmlsafe(self.description.to_s),
					"companyPhone" => htmlsafe(self.phone.to_s),
					"companyPhoneCountryCode" => htmlsafe(self.country_phone_code.to_s),
					"address" => htmlsafe(self.address.to_s),
					"city" => htmlsafe(self.city.to_s),
					"state" => htmlsafe(self.state.to_s),
					"country" => htmlsafe(self.country.to_s),
					"companyWebsite" => htmlsafe(self.website.to_s),
					"companyFacebook" => htmlsafe(self.facebook.to_s),
					"companyTwitter" => htmlsafe(self.twitter.to_s),
					"companyLinkedIn" => htmlsafe(self.linkedin.to_s),
					"companyIndustry" => htmlsafe(self.industry.to_s),
					"companyTeamLeaders" => htmlsafe(self.team.to_s),
					"companyPrivacySetting" => htmlsafe(self.privacy.to_s)
				}
				mobile_tribe.update_company(fields) if self.need_mobile_tribe_attr_update  
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				self.send(rollback_changes)
				return false
			end
		end
	end
    
    #Delete Company Notification

	def delete_company_with_service
		logger.info("Delete Company")
		#success = self.send(:delete_employees)
                #if success
		  if (property(:use_mobile_tribe)) && self.mobiletribe_connect?
			  findme = Company.find_by_id(self.id)
			  unless findme.blank?
				  logger.info("1111111111111111")
				  begin
					  mobile_tribe = Services::MobileTribe::Connector.new
					  mobile_tribe.destroy_company("companyId" => htmlsafe(self.id))
					  self.employee_dept_mt_connect
					  self.send(:delete_employees)
					  #Employee.find_by_company_id(self.id).update_attribute("is_mobiletribe_connect",0)
				  rescue Services::MobileTribe::Errors::MobileTribeError => e
					  logger.info("exception.............")
					  self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
					  self.send(rollback_changes)
					  return false
				  end
			  end
		  end
		#else
		#  return false
		#end 
	end

	def employee_dept_mt_connect
		depts = Department.find_all_by_company_id(self.id)#
		depts.each do |dept|
			dept.update_attribute("is_mobiletribe_connect",0)
		end
		
		employees = Employee.find_all_by_company_id(self.id)#
		employees.each do |employee|
			employee.update_attribute("is_mobiletribe_connect",0)
		end
	end

	def remove_owner_and_company
		Employee.find_by_company_id(self.id).delete
		Company.find_by_id(self.id).delete
	end

	def rollback_changes
		raise ActiveRecord::Rollback, "Something went wrong with MTP, check the logs!"
	end

	def htmlsafe(str)
		@escaped = URI::escape(str.to_s)
		return @escaped
	end

#  def audit_destroy
#
#    p self.employees
#    p self.employees.first.audit
#
#    attr = {}
#    attr[:status] = self.errors.empty? ? Audit::Statuses::SUCCESS : Audit::Statuses::FAILED
#    attr[:name] = "#{self.name}"
#    attr[:description] = {:messages => self.errors.full_messages,
#                          :attributes => self.to_services_attrs.merge({
#                            "created_at" => self.created_at.to_s,
#                            "user_id" => self.user_id})} if attr[:status] == Audit::Statuses::FAILED
#    attr[:associations_audits] = self.employees.map(&:audit).compact
#    p self.create_audit(attr)
#    #audit.associations_audits = self.employees.map(&:audit).compact
#  end
end
