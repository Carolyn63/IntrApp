class User < ActiveRecord::Base
  cattr_accessor :ignore_sogo
  cattr_reader :per_page
  @@per_page = 20

  # The following modules use constants, and with the use of the database, determine what the value should actually be.. 
  
  # Privacy settings
  module Privacy
    PUBLIC = 0
    PRIVATE = 1

    LIST = [
      [I18n.t('models.user.public'), PUBLIC],
      [I18n.t('models.user.private'), PRIVATE]
    ]
    TO_LIST = {
      PUBLIC => I18n.t('models.user.public'),
      PRIVATE => I18n.t('models.user.private')
    }
  end

  # Constant for determining if the user is registered with MT
  module MobileTribeUserState
    NOT_EXIST = 0
    ALREADY_EXIST = 1
    NOT_NEED = 2

    # TRAC 
    # User_deletion 
    # A more elegant solution than editing the schema. 
    COMPANY_PENDING = 3

    ALL = [NOT_EXIST, ALREADY_EXIST, NOT_NEED]

    LIST = [
      [I18n.t('models.user.not_exist'), NOT_EXIST],
      [I18n.t('models.user.already_exist'), ALREADY_EXIST],
      [I18n.t('models.user.no_need'), NOT_NEED]
    ]
    TO_LIST = {
      NOT_EXIST => I18n.t('models.user.not_exist'),
      ALREADY_EXIST => I18n.t('models.user.already_exist'),
      NOT_NEED => I18n.t('models.user.no_need')
    }
  end

  # Constant for determining an administrator/user. 
  module Role
    ADMIN = 0
    USER = 1

    ALL = [ADMIN, USER]
    TO_LIST = {
      ADMIN => "Admin",
      USER => "User"
    }
  end

  # Constant for determining a user's status
  module Status
    ACTIVE = 0
    BLOCKED = 1
    DELETED = 2
    REGISTATION_UNCONFIRMED = 3

    ALL = [ACTIVE, BLOCKED, DELETED, REGISTATION_UNCONFIRMED]

    LIST = [
      [I18n.t("models.user.active"), ACTIVE],
      [I18n.t("models.user.blocked"), BLOCKED],
      [I18n.t("models.user.unconfirmed"), REGISTATION_UNCONFIRMED]
      #[I18n.t("models.user.deleted"), DELETED]
    ]

    TO_LIST = {
      ACTIVE => I18n.t("models.user.active"),
      BLOCKED => I18n.t("models.user.blocked"),
      REGISTATION_UNCONFIRMED => I18n.t("models.user.unconfirmed")
      #DELETED => I18n.t("models.user.deleted")
    }
  end

  module Search
    #SEARCH_FIELDS = %w{firstname lastname login email phone address job_title description}
    SEARCH_FIELDS = %w{firstname lastname login email}
    SEARCH_BY = [
      [I18n.t('models.user.all'), ""],
      [I18n.t('models.user.first_name'), "firstname"],
      [I18n.t('models.user.last_name'), "lastname"],
      [I18n.t('models.user.user_name'), "login"],
      [I18n.t('models.user.email'), "email"],
      #[I18n.t('models.user.phone'), "phone"],
      #[I18n.t('models.user.address'), "address"],
      #[I18n.t('models.user.job_title'), "job_title"],
      #[I18n.t('models.user.description'), "description"]
    ]

    #SORT_FIELDS = %w{firstname lastname username phone job_title}
    SORT_FIELDS = %w{firstname lastname username}
    SORT_BY = [
      [I18n.t('models.user.first_name'), "firstname"],
      [I18n.t('models.user.last_name'), "lastname"],
      [I18n.t('models.user.user_name'), "login"],
      #[I18n.t('models.user.phone'), "phone"],
      #[I18n.t('models.user.job_title'), "job_title"]
    ]
  end

  # Validation for login, user, emails, password
  acts_as_authentic do |config|
    #config.login_field = :email

    config.validates_format_of :email, :with => Authlogic::Regex.email, :message => I18n.t('error_messages.email_invalid', :default => I18n.t('models.employee.should_look_like_email'))
    config.validates_format_of_login_field_options = {:with => Authlogic::Regex.login, :message => I18n.t('error_messages.login_invalid', :default => I18n.t('models.user.should_look_like_login'))}
    config.validates_length_of_password_field_options = {:minimum => 6,  :if => :require_password?}
    config.validates_length_of_password_confirmation_field_options = {:minimum => 6,  :if => :require_password?}
  end

  act_as_services_delete_audit :with_audit_association => :companies, 
                               :additional_audited_columns => %w{created_at login email firstname lastname phone cellphone address job_title id name}

  
  # Activerecord relations. Used to map objects to database columns

  has_attached_file :avatar,
    :styles => { :medium => "70x70", :thumb => "55x55", :big => "187x187"},
    :path => ":rails_root/public/system/avatars/:id/:style/:filename",
    :url => "/system/avatars/:id/:style/:filename",
    :default_url => "/system/avatars/:style/missing.png"
  before_post_process :lowercase_file_extenstion

  has_many :companies, :order => "name ASC"
  has_many :employees
  has_many :active_employees, :class_name => "Employee", :conditions => {:status => Employee::Status::ACTIVE}
  has_many :employers, :class_name => "Company", :through => :employees, :source => :company, :order => "name ASC"
  
  has_many :friendships, :dependent => :destroy
  has_many :friends_friendships, :class_name => "Friendship", :foreign_key => :friend_id, :dependent => :destroy
  has_many :friends, :class_name => "User", :through => :friendships, :source => :friend,
    :conditions => ["friendships.status = ?", Friendship::Status::ACTIVE], :order => "friendships.created_at DESC"

  has_many :incoming_requests, :class_name => "Friendship", :foreign_key => :friend_id,
    :conditions => ["friendship_id = 0"], :order => "created_at DESC"
  has_many :outcoming_requests, :class_name => "Friendship", :foreign_key => :friend_id,
    :conditions => ["friendship_id != 0"], :order => "created_at DESC"

  has_one :audit, :as => :auditable, :order => "created_at DESC"

  validates_presence_of :firstname, :lastname
  validates_format_of   :site, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*((\.|\:)([a-z]{2,5}|[0-9]+))(([0-9]{1,5})?\/.*)?$)/
  validates_format_of   :phone,     :with => /^[+\/\-() 0-9]+$/ ,:allow_blank => true
  validates_format_of   :cellphone, :with => /^[+\/\-() 0-9]+$/ ,:allow_blank => true
  validates_length_of   :phone,     :in => 1..32,  :allow_blank => true 
  validates_length_of   :cellphone, :in => 1..32,  :allow_blank => true 

  validates_acceptance_of :terms_and_conditions, :on => :create, :if => :self_register
  validates_length_of :firstname, :lastname, :in => 1..80
  validates_length_of :job_title, :in => 1..128, :allow_blank => true
  validates_length_of :address,   :in => 1..255, :allow_blank => true
  validates_length_of :city,      :in => 1..255, :allow_blank => true
  validates_length_of :state,     :in => 1..128, :allow_blank => true
  validates_length_of :country,   :in => 1..128, :allow_blank => true
  validates_length_of :login,     :in => 4..40
  validates_length_of :email, :within => 6..50
  
  validates_attachment_content_type :avatar, :content_type => /image/
  validates_attachment_size       :avatar, :less_than => 15.megabytes
  
  attr_accessor :terms_and_conditions, :self_register, :mobile_tribe_create, :need_sogo_update, :need_mobile_tribe_update,
                :old_password, :need_ondeego_employees_update, :need_mobile_tribe_attr_update
              
  attr_accessible :login, :email, :email_confirmation, :password, :password_confirmation, :self_register,
    :terms_and_conditions, :firstname, :lastname, :avatar,
    :avatar_file_name, :avatar_file_size, :avatar_updated_at, :avatar_content_type,
    :friendship_notification, :mobile_tribe_login, :mobile_tribe_password, :mobile_tribe_user_state,
    :description, :site, :sex, :age, :cellphone, :phone, :address, :address2, 
    :role, :status, :job_title, :city, :state, :country, :zipcode,:privacy, :user_password, :linkedin

  after_validation :prepare_decrypt_password, :if => :password_changed?
  after_validation :prepare_need_update_flags
  after_create :create_user_with_service
  #before_create :create_user_with_service, :if => :mobile_tribe_create
  before_update :update_mobile_tribe_user, :if => :need_mobile_tribe_update
  before_update :update_ondeego_employees, :if => :need_ondeego_employees_update
  after_update  :update_sogo_accounts, :if => :need_sogo_update
  #before_destroy :delete_user_with_service, :if => :multi_tenant
  before_destroy :delete_employees
  before_destroy :delete_companies
  before_destroy :delete_mobile_tribe_association_service, :unless => :multi_tenant
  before_destroy :delete_user_with_service, :if => :multi_tenant
  
  
  #before_save :set_not_crypted_user_password

  # TRAC 104
  #
  # Fixes the issue where letters could be added to the phone and cellphone field.

  
	def multi_tenant
		if property(:is_multi_tenant)
			return true
		else
			return false
		end
	end
  

  
  def after_validation
    # Skip errors that won't be useful to the end user
    filtered_errors = self.errors.reject{ |err| %w{ employees }.include?(err.first) }
    self.errors.clear
    filtered_errors.each { |err| self.errors.add(*err) }
  end

  # What
  by_whatever
  
  named_scope :public, :conditions => {:privacy => User::Privacy::PUBLIC}
  named_scope :private, :conditions => {:privacy => User::Privacy::PRIVATE}

	named_scope :public_and_coworkers, lambda {|user|
    user.blank? ? {} : {:conditions => ["id != ? and status=? and company_pending=0 and (privacy = ? or (privacy = ? and id IN (?))) ", user.id, User::Status::ACTIVE,
        User::Privacy::PUBLIC, User::Privacy::PRIVATE, 
        Employee.by_contacts(user).all.map(&:user_id)]}
  }

  named_scope :public_and_coworkers_with_self, lambda {|user|
    user.blank? ? {} : {:conditions => ["users.status=? and privacy = ? or (privacy = ? and id IN (?))", User::Status::ACTIVE,
        User::Privacy::PUBLIC, User::Privacy::PRIVATE,
        Employee.by_contacts(user).all.map(&:user_id)]}
  }

  named_scope :private_coworkers, lambda {|user|
    user.blank? ? {} : {:conditions => ["status=? and privacy = ? and id IN (?)", User::Status::ACTIVE,
        User::Privacy::PRIVATE, Employee.by_contacts(user).all.map(&:user_id)]}
  }

  #SECOND VERSION. It's slow maybe
#  named_scope :public_and_coworkers, lambda {|user|
#    user.blank? ? {} : {:conditions => ["users.id != ? and (users.privacy = ? or
#        (users.privacy = ? and employees.user_id = users.id and employees.company_id IN (?))) ", user.id,
#        User::Privacy::PUBLIC, User::Privacy::PRIVATE,
#        user.employees.map(&:company_id)],
#        :include => [:employees]
#        }
#  }

  named_scope :by_search, lambda {|params|
    params.blank? ? {} : {:conditions => ["users.status=? and (firstname LIKE ? or lastname LIKE ? or login LIKE ? or email LIKE ?)", User::Status::ACTIVE, "%#{params}%", "%#{params}%", "%#{params}%", "%#{params}%"]}
  }

  named_scope :by_company_id, lambda {|company_id|
    company_id.blank? ? {} : {:conditions => ["employees.company_id = ?", company_id], :include => [:employees]}
  }

  named_scope :by_status, lambda {|status|
    status.blank? ? {} : {:conditions => ["users.status = ?", status]}
  }

  named_scope :by_first_letter, lambda {|letter|
    letter.blank? ? {} : {:conditions => ["users.status=? and (lower(firstname) LIKE ? or lower(lastname) LIKE ?)", User::Status::ACTIVE, "#{letter}%", "#{letter}%"]}
  }

    named_scope :by_firstname, lambda {|name|
    name.blank? ? {} : {:conditions => ["users.status=? and lower(firstname) LIKE ?", User::Status::ACTIVE, "#{name}%"]}
  }
   named_scope :by_lastname, lambda {|name|
    name.blank? ? {} : {:conditions => ["users.status=? and lower(lastname) LIKE ?", User::Status::ACTIVE, "#{name}%"]}
  }
  
   named_scope :by_email, lambda {|email|
    email.blank? ? {} : {:conditions => ["users.status=? and email LIKE ?", User::Status::ACTIVE, "#{email}%"]}
  }
  
  named_scope :by_login, lambda {|login|
    login.blank? ? {} : {:conditions => ["users.status=? and login  LIKE ?", User::Status::ACTIVE, "#{login}%"]}
  }  

  def self.find_by_username_or_email(login)
    find_by_login(login) || find_by_email(login)
  end

  #TODO Need remove later
#  def set_not_crypted_user_password
#    self.user_password = self.password unless self.password.blank?
#  end

  #TODO: Maybe remove later
  #  def change_mobile_tribe_login_and_password
  #    self.mobile_tribe_login = self.mobile_tribe_password = "" if User::MobileTribeUserState::NOT_NEED == self.mobile_tribe_user_state.to_i
  #  end

  def self.search_or_filter_users user, params = {}
    params[:sort_by] = !params[:sort_by].blank? && User::Search::SORT_FIELDS.include?(params[:sort_by]) ? params[:sort_by] : User::Search::SORT_FIELDS[0]
    params[:alphabet] = params[:alphabet].to_s.first.underscore
    if params[:search].blank?
     users = User.public_and_coworkers_with_self(user).by_first_letter(params[:alphabet]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
    else
      params[:alphabet] = ""
      params[:search_by] = !params[:search_by].blank? && User::Search::SEARCH_FIELDS.include?(params[:search_by]) ? params[:search_by] : ""
      conditions = params[:search_by].blank? ? {} : {params[:search_by].to_s => params[:search]}
       if params[:search_by].blank?
        users = User.public_and_coworkers_with_self(user).by_search(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
      elsif params[:search_by] == "firstname"
       users = User.public_and_coworkers_with_self(user).by_firstname(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
      elsif params[:search_by] == "lastname"
       users = User.public_and_coworkers_with_self(user).by_lastname(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
      elsif params[:search_by] == "email"
       users = User.public_and_coworkers_with_self(user).by_email(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
      elsif params[:search_by] == "login"
       users = User.public_and_coworkers_with_self(user).by_login(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] + " ASC")
      end
    end
    users
  end

  def htmlsafe(str)
     @escaped = URI::escape(str.to_s)
     return @escaped
  end


  def rollback_changes
     raise ActiveRecord::Rollback, "Something went wrong with MTP, check the logs!"
  end

  def top_company
    company = self.companies.first(:order => "created_at DESC")
    company = self.employers.active_employers.first(:order => "created_at DESC") if company.blank?
    company
  end

  def full_address
    "#{self.address}"
  end

	def name
		"#{self.firstname} #{self.lastname}"
	end

	def company_email_name
		email_name = self.firstname.to_s
		email_name += email_name.blank? ? self.lastname.to_s : "." + self.lastname.to_s
		email_name.gsub(/[^A-Z0-9_\.%\+\-]+/i, '').downcase
	end

	def username
		name = self.login.to_s
		name.gsub(/[^A-Z0-9_\.%\+\-]+/i, '').downcase
	end

	def fullname
		name = self.firstname.to_s
		name += name.blank? ? self.lastname.to_s : "." + self.lastname
		name.gsub(/[^A-Z0-9_\.%\+\-]+/i, '').downcase
	end

  def decrypted_user_password
    self.user_password.blank? ? "" : Tools::AESCrypt.new.decrypt(self.user_password).to_s
#    if !self.user_password.blank?
#      @cache_user_password ||= self.user_password
#      if @decrypted_password.blank? || self.user_password != @cache_user_password
#        @decrypted_password = Tools::AESCrypt.new.decrypt(self.user_password).to_s
#        @cache_user_password = self.user_password
#      end
#    end
#    @decrypted_password
  end

  def status?
    self.status
  end

  def contacts
    Employee.by_contacts(self).all
  end

  #User.search(:without => {:id => User.first.private_not_coworkers_users.map(&:id)}).map(&:id)
  def private_not_coworkers_users
    User.private.all - User.private_coworkers(self)
  end

  def invited_employee?
    Employee.find_by_company_id_and_status_and_user_id
  end

  def has_coworkers?
  end

  def private_not_employers_company
    Company.private.all - self.employers.private.all
  end

  def can_view_user_profile? user
    user.privacy == User::Privacy::PUBLIC || user == self ? true : self.coworker?(user)
  end

  def can_view_company_profile? company
    company.privacy == Company::Privacy::PUBLIC ? true : self.employer?(company)
  end

    def coworker? user
      !Employee.by_contacts(self).by_user_id(user).first.blank?
    end

    def employer? company
      !self.active_employees.by_company_id(company).first.blank?
    end

    def iso_country_code
      ISOCountryCode.iso_country_code(self.country)
    end

  def accepted_published_contacts
    self.owner_companies? ? Employee.by_accepted_published_employees(self).all(:order => "created_at DESC") : []
  end

    def accepted_published_friends
      self.outcoming_requests.published.all
    end
    
    def active?
      true
    end

    def admin?
      self.role == User::Role::ADMIN
    end

    def friend user
      self.friendships.by_friend_id(user.id).first
    end

    def friend? user
      !self.friend(user).blank?
    end

    def active_friend? user
      !self.friend(user).blank? && self.friend(user).active?
    end

    def reject_friend? user
      !self.friend(user).blank? && self.friend(user).reject?
    end

    def pending_friend? user
      !self.friend(user).blank? && self.friend(user).pending?
    end

    def incoming_friend_request_from? user
      !self.incoming_requests.by_user_id(user).blank?
    end

    def is_friendship_notification?
      self.friendship_notification == 1
  end

  def status_active?
    self.status == User::Status::ACTIVE
  end
  
  def status_unconfirmed?
    self.status == User::Status::REGISTATION_UNCONFIRMED
  end

  def blocked?
    self.status == User::Status::BLOCKED
  end

  def change_status status
    self.update_attributes(:status => status)
  end

  def mobile_tribe_login
    self.login
  end

  def mobile_tribe_password
    self.decrypted_user_password
  end

  def mobile_tribe_user?
    if self.new_record?
      false
    else
      true
      #Now for mobile tribe used user login and password, so user mobile tribe anyway
#      u = User.find_by_id self.id
#      !u.blank? && !u.mobile_tribe_login.blank? && !u.mobile_tribe_password.blank?
    end
  end

  def remove_mobile_tribe_association
    if !property(:multi_tenant)
    self.send(:delete_mobile_tribe_association_service)
    if self.errors.blank?
      self.update_attributes(:mobile_tribe_login => "",
        :mobile_tribe_password => "",
        :mobile_tribe_user_state => MobileTribeUserState::NOT_EXIST)
    else
      false
    end
   end
  end

  def owner_companies?
    !self.companies.blank?
  end
  
  def has_companies?
    self.companies.blank?
  end

  def has_active_employee?
    !self.first_active_employee.blank?
  end

  def first_active_employee
    self.employees.active.first
  end

  def login_once?
    self.login_count > 0
  end

  def fetch_id
    return self.id
  end

  def has_company? (user)
      return !Company.find_last_by_user_id(user).blank?
  end

  def is_employee? (user)
      return Employee.find_last_by_user_id(user).blank?
  end

  #TRAC ## 
  #
  # Minor fix regarding employee link. 
  def can_owner_add_ippbx (user, owner)
    logger.info(user.id)
    company = Company.find_by_user_id(owner.id)
    unless company.blank?
      unless user.employees[0].blank?
       if !company.ippbx.blank? and  owner == company.admin and user.employees[0].company_id == company.id
        logger.info("true")
        return true
       else
        return false
       end
      end
    end
  end
  
  def user_has_ippbx?(user)
    employee = user.employees[0]
    logger.info(employee)
    unless employee.blank?
      unless employee.ippbx.blank?
        return true
      else
        return false
      end
    end
  end
  
  def may_be_coworker?(user)
    if property(:multi_company)
      return !self.companies.blank?
    else
      maybe_coworker =  Employee.find_last_by_user_id(user)
      if !self.companies.blank? 
        if maybe_coworker.blank? 
          return true
        elsif maybe_coworker.status == Employee::Status::REJECTED && self.companies[0].id != maybe_coworker.company_id
          return true
        else
          return false  
        end
       end
    end
  end

  # TRAC 191 - Models - Users - User_Invited_Employee
  #
  # An attempt to find out how to make this work
  
  def user_invited_employee(user, owner)
    company = Company.find_by_user_id(owner.id)
    employee = Employee.find_by_user_id_and_company_id_and_company_pending(user.id, company.id, 1)
    if employee.blank?
      return false    
    elsif !employee.blank?
      return true
    end
  end

  def delete_exist_rejected_employee_of_user(user, company)
    if !property(:multi_company) && !user.blank?
      exist_rejected_employee = Employee.find_by_user_id_and_company_id_and_status(user.id, company.id, Employee::Status::REJECTED)
#      exist_rejected_employee = user.employees.first(:conditions => ["company_id IN(?) and status = ?", company.id, Employee::Status::REJECTED])
      exist_rejected_employee.delete unless exist_rejected_employee.blank?
    end
  end

  def to_services_attrs
    {"app_central" =>  {},
     "sogo" =>         {},
     "mobile_tribe" => {"login" => self.login, "firstname" => self.firstname, "lastname" => self.lastname, "is_connect" => self.mobile_tribe_user?} }
  end

  def deliver_activation_instructions!
    reset_perishable_token!
    Notifier.deliver_activation_instructions(self)
  end

  def deliver_welcome!
    reset_perishable_token!
    Notifier.deliver_welcome(self)
  end
  
  def deliver_confirm!
    reset_perishable_token!
    Notifier.deliver_confirm(self)
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end
  
  
  def mobiletribe_connect!
    self.update_attribute("is_mobiletribe_connect", 1)
  end

  
  def mobiletribe_connect?
    self.is_mobiletribe_connect == 1
  end
  
	def use_ippbx?
		success = false
		if property(:use_ippbx)
			success = true
		end
		return success
	end


  #TODO: Remove later
#  def need_ondeego_update?
#    need = false
#    unless self.employees.blank?
#      u = User.find_by_id(self.id)
#      %w{firstname lastname address city state country}.each do |f|
#        return true if u.send(f.to_sym) != self.send(f.to_sym)
#      end
#    end
#    need
#  end

  def profile_complete 
    profile_fields = [:login, :email, :firstname, :lastname, :avatar_file_name, :address, :phone, :cellphone,
      :age, :sex, :site, :description, :job_title, :city, :state, :country, :linkedin
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

  # TRAC 195 - Models - Users - Company_Created_Employee?
  #
  # Gives the company_pending value to the templates, which we will use to hide the user from the site until they have accepted/rejected their invitation.

  def company_created_employee?
    if self.company_pending == 0
     return false
    elsif self.company_pending == 1
      return true
    end
  end
  
  def service_email
    self.login + "@" + property(:sogo_email_domain)
  end

  private

  def prepare_need_update_flags
    self.need_mobile_tribe_update = false
    self.need_sogo_update = false
    unless self.new_record?
      u = User.find_by_id(self.id)
      #Sogo
      self.need_sogo_update = self.send(:password_changed?) ||
                              %w{firstname lastname}.any? do |f|
                                u.send(f.to_sym) != self.send(f.to_sym)
                              end
      #MobileTribe
      if self.mobile_tribe_user?
        if property(:is_multi_tenant)
        self.need_mobile_tribe_attr_update = %w{firstname lastname login email cellphone phone address password job_title site age sex privacy}.any? do |f|
                                         u.send(f.to_sym) != self.send(f.to_sym)
                                      end
       else
       self.need_mobile_tribe_attr_update = %w{firstname lastname login email cellphone phone address}.any? do |f|
                                         u.send(f.to_sym) != self.send(f.to_sym)
                                      end
       end
        self.need_mobile_tribe_update = self.need_mobile_tribe_attr_update || self.send(:password_changed?)
      end

      #OnDeego
      unless self.employees.blank?
        self.need_ondeego_employees_update = %w{firstname lastname address city state country}.any? do |f|
                                               u.send(f.to_sym) != self.send(f.to_sym)
                                             end
      end
    end
  end

  def prepare_decrypt_password
    unless self.password.blank?
      begin
          self.old_password = self.decrypted_user_password
        rescue Exception
          self.old_password = self.user_password
        end
        self.user_password = Tools::AESCrypt.new.encrypt(self.password)
      end
    end

    #TODO Remove its later
  #  def need_mobile_tribe_update?
  #    if !self.new_record? && self.mobile_tribe_user?
  #      return true if self.send(:password_changed?)
  #      u = User.find_by_id(self.id)
  #      %w{firstname lastname login phone address}.each do |f|
  #        return true if u.send(f.to_sym) != self.send(f.to_sym)
  #      end
  #    end
  #    return false
  #  end
  #
  #  def need_sogo_update?
  #    self.need_sogo_update = false
  #    unless self.new_record?
  #      u = User.find_by_id(self.id)
  #      %w{firstname lastname}.each do |f|
  #        self.need_sogo_update = true && break if u.send(f.to_sym) != self.send(f.to_sym)
  #      end
  #    end
  #    return self.need_sogo_update
  #  end

    def lowercase_file_extenstion
      extension = File.extname(self.avatar.original_filename).gsub(/^\.+/, '')
      filename = self.avatar.original_filename.gsub(/\.#{extension}$/, '')
      self.avatar.instance_write(:file_name, "#{filename}.#{extension.downcase}")
    end

    def update_ondeego_employees
      if property(:use_ondeego)
        begin
          self.employees.each do |employee|
            employee.send(:send_update_ondeego_employee, self) if employee.ondeego_connect?
          end
        rescue Services::OnDeego::Errors::OnDeegoError => e
          self.errors.add_to_base("#{I18n.t('models.company.appcentrall_error')} #{e.to_s}")
          return false
        end
      end
    end

  def self.delete_orphans
      logger.info("CronJob Delete Inactive user .......#{Time.now()}....")
      users = User.find_by_sql("SELECT u.id as id FROM users u LEFT JOIN employees e ON u.id=e.user_id WHERE e.user_id IS NULL AND u.last_login_at < NOW() - INTERVAL 30 DAY")
      users.each do |user|
        logger.info("Delete User by Cron User_id.......#{user.id}")
        #user.destroy
      end
      
      company_users = User.find_by_sql("SELECT u.id as id FROM users u LEFT JOIN companies c ON u.id=c.user_id WHERE c.user_id IS NULL AND u.created_at < NOW() - INTERVAL 10 DAY")
      company_users.each do |company_user|
      logger.info("Delete User by Cron User_id.......#{company_user.id}")
      #company_user.destroy
      end
  end
  
  def create_user_with_service
    logger.info("Creating user>>>>>>>>>>>>>>>>>>>>>>>>")
    if property(:use_mobile_tribe)

      password_for_services = self.password
      #self.mobile_tribe_login = self.login
      self.mobile_tribe_user_state = User::MobileTribeUserState::NOT_EXIST

      #if !self.mobile_tribe_user? && User::MobileTribeUserState::NOT_NEED != self.mobile_tribe_user_state.to_i
        begin
          logger.info("create user2")
          mobile_tribe = Services::MobileTribe::Connector.new
          if (property(:is_multi_tenant))
            logger.info("create user 3")
            logger.info("User Id........#{self.id}")
          mobile_tribe.create_user("userId" => self.id,
          "username" => self.mobile_tribe_login,
          "password" => password_for_services,
          "firstName" => htmlsafe(self.firstname),
          "lastName" => htmlsafe(self.lastname),
          "email" => htmlsafe(self.email.to_s)) if User::MobileTribeUserState::NOT_EXIST == self.mobile_tribe_user_state.to_i
          else
            logger.info("non multitenant......")
            mobile_tribe.register_user("mtUserName" => self.mobile_tribe_login,
            "mtUserPassword" => password_for_services,
            "firstName" => htmlsafe(self.firstname),
            "lastName" => htmlsafe(self.lastname),
            "email" => htmlsafe(self.email.to_s),
            "phone" => htmlsafe(self.phone.to_s),
            "cellphone" => htmlsafe(self.cellphone.to_s),
            "address" => htmlsafe(self.address.to_s)) if User::MobileTribeUserState::NOT_EXIST == self.mobile_tribe_user_state.to_i
            
            mobile_tribe.register_credentials(self.mobile_tribe_login, password_for_services,
            "portalUserId" => self.login,
            "portalPassword" => password_for_services)
          end

              self.update_attribute("is_mobiletribe_connect", 1)

          unless self.employees.blank?
            #Create Calendar and Mail if sogo exist
            employee = self.employees.sogo_connected.first
            unless employee.blank?
              mobile_tribe.create_calendar_and_mail(self.mobile_tribe_login, password_for_services,
                      "portalUserId" => employee.company_email,
                      "password" => password_for_services,
                      "crypted_password" => password_for_services)
              employee.update_attribute("is_mobiletribe_connect", 1)
            end
            #Update address book
            #mobile_tribe.contacts_or_friends_update("scope" => "ADDRESSBOOK", "userIds" => self.id.to_s)
          end
        self.mobiletribe_connect!
        rescue Services::MobileTribe::Errors::MobileTribeError => e
          self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
          User.find_by_id(self.id).destroy
          self.send(:rollback_changes)
        end
      end
    #end
  end
 
  
	def update_mobile_tribe_user
		logger.info("updating user>>>>>>>>>>>>>>>>>>>>>")
		if property(:use_mobile_tribe) && self.mobiletribe_connect? && self.mobile_tribe_user?
			begin
				mobile_tribe = Services::MobileTribe::Connector.new
				sogo = Services::Sogo::Wrapper.new
				mt_password = self.send(:password_changed?) ? self.old_password || User.find_by_id(self.id).mobile_tribe_password : self.mobile_tribe_password
				if property(:is_multi_tenant)
					emp = Employee.find_last_by_user_id(self.id)
					

					mobile_tribe.update_user(
						self.id,mt_password,
						"userId" => htmlsafe(self.id),  
						"firstName" => htmlsafe(self.firstname.to_s),
						"lastName" => htmlsafe(self.lastname.to_s),
						"email" => htmlsafe(self.email.to_s),
						"age" => htmlsafe(self.age.to_s),
						"gender" => htmlsafe(self.sex.to_s),
						"jobTitle" => htmlsafe(self.job_title.to_s),   
						"website" => htmlsafe(self.site.to_s),
						"description" => htmlsafe(self.description.to_s),
						"privacy" => htmlsafe(self.privacy.to_s),
						"phone" => htmlsafe(self.phone.to_s),
						"address" => htmlsafe(self.address.to_s),
						"cellphone" => htmlsafe(self.cellphone.to_s),
						"city" => htmlsafe(self.city.to_s),
						"state" => htmlsafe(self.state.to_s),
						"country" => htmlsafe(self.country.to_s),
						"password" => htmlsafe(self.old_password .to_s),
						"newPassword" =>htmlsafe(self.password.to_s)
					) if self.need_mobile_tribe_update 

					if emp && emp.status == "active"
						begin
							fields = {
								"companyId" => htmlsafe(emp.company_id.to_s),
								"employeeId" => htmlsafe(emp.id.to_s),
								"firstName" => htmlsafe(self.firstname),
								"lastName" => htmlsafe(self.lastname),
								"status" => htmlsafe(emp.status.to_s),
								"email" => htmlsafe(self.email.to_s),
								"jobTitle" => htmlsafe(self.job_title.to_s),
								"officePhone" => htmlsafe(self.phone.to_s),
								"cellPhone" => htmlsafe(self.cellphone.to_s),
								#"password" => htmlsafe(mt_password.to_s),
								"password" => htmlsafe(self.old_password.to_s),
								"newpassword" => htmlsafe(self.password.to_s)
							} 
							unless emp.department_id.blank?
								fields['departmentId'] = htmlsafe("-"+emp.department_id.to_s)
							else
								fields['departmentId'] = htmlsafe("")
							end

							

							mobile_tribe.update_employee(fields) if self.need_mobile_tribe_update

						rescue Services::MobileTribe::Errors::MobileTribeError => e
							self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
							self.send(rollback_changes)
							return false
						end
        # if the employee is actually connected to sogo
						if emp && emp.is_sogo_connect == 1
							begin
								sogo.update_user(:email => emp.company_email, 
								:password => emp.email_password,
								:crypted_password => Tools::MysqlEncrypt.mysql_encrypt(emp.email_password),
								:full_name => emp.user.name)
							rescue Services::Sogo::Errors::OnWrapperError => e
								self.errors.add_to_base("#{I18n.t('models.company.sogo_error')} #{e.to_s}")
								self.send(rollback_changes)
								return false
							end
						end
					end 
				else
					mobile_tribe.modify_user(
						self.mobile_tribe_login, 
						mt_password,
						"firstName" => self.firstname,
						"lastName" => self.lastname,
						"email" => self.email.to_s,
						"phone" => self.phone.to_s,
						"cellphone" => self.cellphone.to_s,
						"address" => self.address.to_s
					) if self.need_mobile_tribe_attr_update

					mobile_tribe.change_user_password(self.mobile_tribe_login, mt_password, "newPassword" => self.password) if self.send(:password_changed?)
					#self.mobile_tribe_password = self.password || self.user_password
				end
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				self.send(rollback_changes)
				return false
			end
		end
	end
 
 

  def delete_user_with_service
    logger.info("Deleting User>>>>>>>>>>>>>>>>>>>>>>.")
    if(property(:use_mobile_tribe)) && self.mobiletribe_connect?
      begin
        mobile_tribe = Services::MobileTribe::Connector.new
        mobile_tribe.destroy_user("userId" => self.id)
      rescue Services::MobileTribe::Errors::MobileTribeError => e
        self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
        self.send(rollback_changes)
      end
    end
  end

  def update_sogo_accounts
    if property(:use_sogo)
      employees = self.employees.sogo_connected.all
      unless employees.blank?
        employees.each do |e|
          e.send(:update_sogo_account)
        end
      end
    end
  end

  # Deletes a company 
  def delete_companies
    self.companies.each do |company|
      company.destroy
      unless company.errors.empty?
        self.errors.add_to_base("#{company.errors.on_base}}")
        company.errors.on_base.each { |e| self.errors.add_to_base("Error deleting Company ##{company.id}: #{e}") }
        return false
      end
    end
  end

  def delete_employees
    association_errors = []
    self.employees.each do |employee|
      employee.destroy
      unless employee.errors.empty?
        #self.errors.add_to_base(I18n.t('models.company.employee_delete_error') + " #{employee.errors.on_base}}")
        association_errors << "Error deleting Employee ##{employee.id}: #{employee.errors.full_messages.to_a.join('; ')}"
      end
    end
    if association_errors.size > 5
      self.errors.add_to_base("Error deleting of #{association_errors.size} Employees")
    else
      association_errors.each {|e| self.errors.add_to_base("#{e}") }
    end
  end

  def delete_mobile_tribe_association_service
    if property(:use_mobile_tribe) && self.mobile_tribe_user?
      begin
        #Services::MobileTribe::Connector.new.remove_association(self.mobile_tribe_login, self.mobile_tribe_password)
        Services::MobileTribe::Connector.new.remove_association(self.mobile_tribe_login, self.mobile_tribe_password)
      rescue Services::MobileTribe::Errors::MobileTribeError => e
        self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
      end
    end
  end

end
