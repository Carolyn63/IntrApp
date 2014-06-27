class Application < ActiveRecord::Base
  module Status
    ACTIVE = 0
    DEACTIVATED = 1

    ALL = [ACTIVE, DEACTIVATED]

    LIST = [
      ['Active', ACTIVE],
      ['Deactivated', DEACTIVATED]
    ]

    TO_LIST = { ACTIVE => 'Active', DEACTIVATED => 'Deactivated' }
  end

  module Approve
    OFF = 0
    ON = 1
    ALL = [OFF, ON]
    LIST = [
      ['No', OFF],
      ['Yes', ON]
    ]

    TO_LIST = { OFF => 'Off', ON => 'On' }
  end

  module PaymentType

    FREE = "free"
    ONCE = "once"
    MONTHLY = "monthly"
    ALL = [FREE, ONCE, MONTHLY]

    LIST = [
      ['Free', FREE],
      ['Once', ONCE],
      ['Monthly', MONTHLY]
      ]

    TO_LIST = { FREE => 'Free', ONCE => 'Once',MONTHLY => 'Monthly'}

  end

	module AppType
		PUBLIC = "public"
		PRIVATE = "private"

		ALL = [PUBLIC, PRIVATE]

		LIST = [
			['Public', PUBLIC],
			['Private', PRIVATE]
		]

		TO_LIST = { PUBLIC => 'Public', PRIVATE => 'Private' }
	end

  attr_accessor :assign_company

  include AASM
  aasm_column :payment_type
  aasm_state :free
  aasm_state :once
  aasm_state :monthly
  aasm_state :monthly_per_employee
  aasm_state :monthly_addition

  include Application::SearchOrFilterApplications
  include Application::ScreenAndBinFileSizeValidation

  has_many :categorizations, :dependent => :destroy
  has_many :categories, :through => :categorizations
  
  has_many :orders, :dependent => :destroy
  has_many :application_plans, :dependent => :destroy
  has_one  :basic_plan , :class_name => "ApplicationPlan", :conditions => {:status => ApplicationPlan::Nature::BASIC}

  has_many :devicefications, :dependent => :destroy
  has_many :devices, :through => :devicefications
  
  has_many :industrializations, :dependent => :destroy
  has_many :industries, :through => :industrializations
  
  has_many :countrifications, :dependent => :destroy
  has_many :countries, :through => :countrifications

  has_many :companifications, :dependent => :destroy

  has_many :active_companies, :source => :company,
  :through => :companifications,
  :conditions => ["companifications.status = ?", Companification::Status::APPROVED]

  #has_many :active_companies, :source => :company,
  #:through => :companifications

  has_many :companies, :through => :companifications

  has_many :typizations, :dependent => :destroy
  has_many :application_types, :through => :typizations

  has_many :employee_applications, :dependent => :destroy
  has_many :employees, :through => :employee_applications

  has_many :approved_employees, :through => :employee_applications, :source => :employee,
  :conditions => ["employee_applications.status = ?", EmployeeApplication::Status::APPROVED]

  #has_many :approved_employees, :through => :employee_applications, :source => :employee

  has_many :department_applications, :dependent => :destroy
  has_many :departments, :through => :department_applications
  has_many :orders
  mount_uploader :logo, ApplicationLogoUploader
  mount_uploader :screenshot0, ApplicationScreenshotUploader
  mount_uploader :screenshot1, ApplicationScreenshotUploader
  mount_uploader :screenshot2, ApplicationScreenshotUploader

  #mount_uploader :bin_file1, ApplicationBinFileUploader
  #mount_uploader :bin_file2, ApplicationBinFileUploader

  named_scope :private, lambda{|company_id| 
  company_id.blank? ? {} :{ :conditions =>["app_type =? and company_id =?", "private", company_id]}}
  named_scope :public, lambda{{ :conditions =>{:app_type => "public"}}}
  named_scope :available, lambda { { :conditions => { :status => Application::Status::ACTIVE } } }
  named_scope :by_status, lambda {|status| status.blank? ? {} : { :conditions => ["applications.status = ?", status] } }
  named_scope :by_company_id, lambda {|company_id| company_id.blank? ? {} : {:conditions => ["companifications.company_id = ?", company_id], :joins => [:companifications]} }
  named_scope :by_category_id, lambda {|category_id| category_id.blank? ? {} : {:conditions => ["categorizations.category_id = ?", category_id], :joins => [:categorizations]} }
  named_scope :by_device_id, lambda {|device_id| device_id.blank? ? {} : {:conditions => ["devicefications.device_id = ?", device_id], :joins => [:devicefications]} }
  named_scope :by_industry_id, lambda {|industry_id| industry_id.blank? ? {} : {:conditions => ["industrializations.industry_id = ?", industry_id], :joins => [:industrializations]} }
  named_scope :by_country_id, lambda {|country_id| country_id.blank? ? {} : {:conditions => ["countrifications.country_id = ?", country_id], :joins => [:countrifications]} }
  named_scope :by_application_type_id, lambda {|application_type_id|
  application_type_id.blank? ? {} : {:conditions => ["typizations.application_type_id = ?", application_type_id], :joins => [:typizations]} }
  named_scope :by_category_ids, lambda {|category_ids| category_ids.blank? ? {} : {:conditions => ["categorizations.category_id IN(?)", category_ids], :joins => [:categorizations]} }
  named_scope :by_device_ids, lambda {|device_ids| device_ids.blank? ? {} : {:conditions => ["devicefications.device_id IN(?)", device_ids], :joins => [:devicefications]} }
  named_scope :by_industry_ids, lambda {|industry_ids| industry_ids.blank? ? {} : {:conditions => ["industrializations.industry_id IN(?)", industry_ids], :joins => [:industrializations]} }
  named_scope :by_country_ids, lambda {|country_ids| country_ids.blank? ? {} : {:conditions => ["countrifications.country_id IN(?)", country_ids], :joins => [:countrifications]} }
  
  named_scope :by_employee_ids, lambda {|employee_ids| employee_ids.blank? ? {} : {:conditions => ["employee_applications.employee_id IN(?)", employee_ids], :joins => [:employee_applications]} }
  named_scope :by_department_ids, lambda {|department_ids|
  department_ids.blank? ? {} : {:conditions => ["department_applications.department_id IN(?)", department_ids], :joins => [:department_applications]} }

  named_scope :for_employees, lambda {|employee_ids|
  employee_ids.blank? ? {:conditions => "FALSE"} : {:conditions => ["employee_applications.employee_id IN(?) and employee_applications.status = ?",
  employee_ids, EmployeeApplication::Status::APPROVED], :joins => [:employee_applications]} }

  named_scope :by_approved_company_id, lambda { |company_id|
  company_id.blank? ? {} : {:conditions => ["companifications.company_id = ? and (companifications.status =? or companifications.status =? or companifications.status =?)", company_id, Companification::Status::APPROVED, Companification::Status::PAID, Companification::Status::TRIAL], :joins => [:companifications]}
  }
  named_scope :by_approved_employee_ids, lambda { |employee_ids|
  employee_ids.blank? ? {} : {:conditions => ["employee_applications.employee_id IN(?) and employee_applications.status = ?", employee_ids, EmployeeApplication::Status::APPROVED],
  :joins => [:employee_applications]} }

	named_scope :by_first_letter, lambda {|letter|
		#letter.blank? ? {} : {:conditions => ["name LIKE ?", "#{letter}%"]}
		#edited by jhlee on 20120611
		letter.blank? ? {} : {:conditions => ["name LIKE ?", "%#{letter}%"]}
	}
  
  validate :screen_and_bin_file_size_validation

  validates_presence_of :name
  validates_presence_of :devices
  validates_inclusion_of :status, :in => Application::Status::ALL

  validates_presence_of :departments_count
  validates_presence_of :approved_employees_count, :employees_count
  after_create :create_plan 
  after_create :create_companifcation
  after_update :update_plan 

  alias_method :origin_department_ids=, :department_ids=



  def department_ids=(department_ids)
    #Call destroy_all manually for call destroy callbacks, the rails method uses delete_all (
    #    Application.transaction do
    #      ids = (department_ids || []).reject(&:blank?).map(&:to_i)
    #      self.departments.each do |department|
    #        DepartmentApplication.destroy_all(:application_id => self.id, :department_id => department.id) unless ids.include?(department.id)
    #      end
    #    end

    other_ids = assign_company ? self.departments.all(:conditions => ["company_id != ?", assign_company.id]).map(&:id) : []
    department_ids = (department_ids || []).reject(&:blank?).map(&:to_i) + other_ids
    self.origin_department_ids = department_ids.uniq
  end

  alias_method :origin_company_ids=, :company_ids=

  def company_ids=(company_ids)
    #Approve pending application requests
    ids = (company_ids || []).reject(&:blank?).map(&:to_i)
    pending_or_reject_requests = self.companifications.pending_or_rejected
    Companification.transaction do
      pending_or_reject_requests.each do |c|
        c.update_attribute(:status, Companification::Status::APPROVED) if ids.include?(c.company_id)
      end
    end
    company_ids = (company_ids || []) + pending_or_reject_requests.map(&:company_id).map(&:to_s)

    #Call destroy_all manually for call destroy callbacks, the rails method uses delete_all (
    #    Companification.transaction do
    #      ids = (company_ids || []).reject(&:blank?).map(&:to_i)
    #      self.companies.each do |company|
    #        Companification.destroy_all(:application_id => self.id, :company_id => company.id) unless ids.include?(company.id)
    #      end
    #    end
    self.origin_company_ids = company_ids.uniq
  end

  alias_method :origin_employee_ids=, :employee_ids=

  def employee_ids=(employee_ids)
    #Approve pending emplpoyee application requests
    ids = (employee_ids || []).reject(&:blank?).map(&:to_i)
    pending_or_reject_requests = self.employee_applications.pending_or_rejected
    EmployeeApplication.transaction do
      pending_or_reject_requests.each do |c|
        c.update_attribute(:status, EmployeeApplication::Status::APPROVED) if ids.include?(c.employee_id)
      end
    end
    other_ids = assign_company ? self.employees.all(:conditions => ["company_id != ?", assign_company.id]).map(&:id) : []
    employee_ids = (employee_ids || []) + pending_or_reject_requests.map(&:employee_id).map(&:to_s) + other_ids

    #Call destroy_all manually for call destroy callbacks, the rails method uses delete_all (
    # EmployeeApplication.transaction do
    #   ids = (employee_ids || []).reject(&:blank?).map(&:to_i)
    #   self.employees.each do |employee|
    #     EmployeeApplication.destroy_all(:application_id => self.id, :employee_id => employee.id) unless ids.include?(employee.id)
    #   end
    # end
    self.origin_employee_ids = employee_ids.uniq
  end

  def available_for?(company = nil, employee = nil)
    if company.present?
    self.companifications.approved.find_by_company_id(company.id).present? or   self.companifications.paid.find_by_company_id(company.id).present? or self.companifications.trial.find_by_company_id(company.id).present?
    elsif employee.present?
    self.employee_applications.approved.find_by_employee_id(employee.id).present?
    else
    false
    end
  end

  def request_for(company = nil, employee = nil, payment_type = nil)
    if company.present?
    self.companifications.find_by_company_id(company.id)
    elsif employee.present?
    self.employee_applications.find_by_employee_id(employee.id)
    else
    nil
    end
  end

  def self.per_page; 5; end

  def self.search_or_filter_applications user, params = {}
    if params[:order_by] == "most_popular_first"
    order_by = "approved_companies_count DESC"
    else
    order_by = "name ASC"
    end
    if params[:search].blank?
    applications = Application.by_status(params[:status]
    ).by_company_id(params[:company_id]
    ).by_category_ids(params[:categories_in]
    ).by_device_ids(params[:devices_in]
    ).by_industry_ids(params[:industries_in]
    ).by_country_ids(params[:countries_in]
    ).by_application_type_id(params[:application_type_id]
    ).by_employee_ids(params[:employees_in]
    ).paginate(:page => params[:page], :per_page => per_page, :order => order_by, :group=> "applications.id")
    else
    applications = Application.by_first_letter(params[:search]).by_status(params[:status]
    ).by_company_id(params[:company_id]
    ).by_category_ids(params[:categories_in]
    ).by_device_ids(params[:devices_in]
    ).by_industry_ids(params[:industries_in]
    ).by_country_ids(params[:countries_in]
    ).by_application_type_id(params[:application_type_id]
    ).by_employee_ids(params[:employees_in]
    ).paginate(:page => params[:page], :per_page => per_page, :order => order_by, :group=> "applications.id")

    end
    applications
  end

  ############ apps billing ###################

  def basic_plan #return applications plan
    logger.info(self.id)
    return ApplicationPlan.find_by_application_id_and_application_nature(self.id, "basic")
  end

  def create_plan
    logger.info("111111111111111111111111111")
    if self.status == Application::Status::ACTIVE
    active = 1
    else
    active = 0
    end
    fields = {:application_id => self.id, :code => self.name.gsub(/[^0-9a-z\s]/i, ''), :active => active, :amount => self.price, :payment_type => self.payment_type, :currency => property(:default_currency), :application_nature => "basic",
     :default_employees_count => 0
    }
    plan = ApplicationPlan.new(fields)
    plan.save
  end
  
 def update_plan 
    logger.info("111111111111111111111111111")
    if self.status == Application::Status::ACTIVE
    active = 1
    else
    active = 0
    end
		plan = ApplicationPlan.find_by_application_id_and_application_nature(self.id, "basic")
    
    fields = {:application_id => self.id, :code => self.name.gsub(/[^0-9a-z\s]/i, ''), :active => active, :amount => self.price, :payment_type => self.payment_type, :currency => property(:default_currency), :application_nature => "basic"
    }

    plan.update_attributes(fields)
 
 end
 
	def create_companifcation
		logger.info(self.app_type)
		if self.company_id.present? and self.app_type == "private"
			plan = self.basic_plan
			@company = Company.find_by_id(self.company_id)

			amount = plan.amount
			if amount == 0 
				status = Companification::Status::APPROVED
			else
				status = Companification::Status::PAID
				payment_params = {
					'user_id' => @company.user_id,
					'company_id' => @company.id,
					'email' => '',
					'payer_email'=> '',
					'payment_service' => '',
					'transaction_type' => "subscr_payment",
					'transaction_status' => "Completed",
					'transaction_date' => Time.now,
					'amount' => amount,
					'plan_ids' => plan.id,
				}
				payment = Payment.new(payment_params)
				payment.save
			end

			request = @company.companifications.build(:application => self, :status => status, :requested_at => Time.now, :plan_id => plan.id)
			request.save
		end 
	end

end
