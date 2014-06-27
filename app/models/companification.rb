require 'aasm'

class Companification < ActiveRecord::Base

  cattr_reader :per_page
  @@per_page = 30

  module Status
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    PAID = "paid"
    TRIAL = "trial"

    ALL = [PENDING, APPROVED, REJECTED, PAID, TRIAL]

    LIST = [
      [I18n.t('models.companification.approved'), APPROVED],
      [I18n.t('models.companification.pending'), PENDING],
      [I18n.t('models.companification.rejected'), REJECTED],
      [I18n.t('models.companification.paid'), PAID],
      [I18n.t('models.companification.trial'), TRIAL]
    ]

    TO_LIST = {
      PENDING => I18n.t('models.companification.pending'),
      APPROVED => I18n.t('models.companification.approved'),
      REJECTED => I18n.t('models.companification.rejected'),
      PAID => I18n.t('models.companification.paid'),
      TRIAL => I18n.t('models.companification.trial')
    }
  end


  belongs_to :application
  belongs_to :application_plan, :foreign_key => :plan_id
  belongs_to :company
  belongs_to :order
  validates_presence_of :application
  validates_presence_of :application_plan
  validates_presence_of :company
  #validates_uniqueness_of :company_id, :scope => :application_id

   # AASM
  include AASM
  aasm_column :status
  aasm_initial_state :approved
  aasm_state :pending, :enter => :update_requested_at
  aasm_state :approved
  aasm_state :cancelled
  aasm_state :rejected
  aasm_state :paid
  aasm_state :trial

  aasm_event :approve do
    transitions :to => :approved, :from => [:pending]
  end

  aasm_event :reject do
    transitions :to => :rejected, :from => [:pending]
  end

  aasm_event :resend do
    transitions :to => :pending, :from => [:rejected]
  end

  named_scope :approved, :conditions => {:status => Companification::Status::APPROVED}
  named_scope :pending, :conditions => {:status => Companification::Status::PENDING}
  named_scope :pending_or_rejected, :conditions => ["status IN(?)", [Companification::Status::PENDING, Companification::Status::REJECTED]]
  named_scope :paid, :conditions => {:status => Companification::Status::PAID}
  named_scope :trial, :conditions => {:status => Companification::Status::TRIAL}
  named_scope :addons, lambda {|application_id, plan_id, company_id|
  application_id.blank? or  plan_id.blank? ? {} :  {:conditions => ["application_id =? and plan_id !=? and company_id =?",application_id, plan_id, company_id]}
  }

  after_destroy :unassign_application_from_employees_and_department

  protected

  def update_requested_at
    self.requested_at = Time.now
  end

  def unassign_application_from_employees_and_department
    EmployeeApplication.destroy_all(["application_id = ? AND employee_id IN(?)", self.application.id, self.company.employees.map(&:id)])
    DepartmentApplication.destroy_all(["application_id = ? AND department_id IN(?)", self.application.id, self.company.departments.map(&:id)])
  end

  # include Companification::ApplicationApprovedCompaniesCounter
  after_create do |record|
    if record.approved?
      Application.increment_counter(:approved_companies_count, record.application_id)
      company = Company.find_by_id(record.company_id)
      employee = Employee.find_by_user_id(company.user_id)
      application = Application.find_by_id(record.application_id)
      request = employee.employee_applications.build(:application => application, :status => EmployeeApplication::Status::APPROVED, :requested_at => Time.now)
      request.save
    
    end
  end

  after_update do |record|
    if record.status_changed? && (record.approved?|| record.trial?|| record.paid?)
      Application.increment_counter(:approved_companies_count, record.application_id)
 
         company = Company.find_by_id(record.company_id)
         user = User.find_by_id(company.user_id)
         payment = Payment.find_by_id(record.payment_id)
         employee= Employee.find_by_user_id(user.id)
	 plan = ApplicationPlan.find_by_id(record.plan_id)
	 application = Application.find_by_id(plan.application_id)
	 request = employee.employee_applications.build(:application => application, :status => EmployeeApplication::Status::APPROVED, :requested_at => Time.now)
         request.save
	 
 
         if record.payment_id.blank?
         Notifier.deliver_application_details(user.email, user.id,user.login, plan)
         else
         Notifier.deliver_payment_notification(user.email,user.id, user.login, plan)
         end

    elsif record.status_changed? and record.cancelled?
      Application.decrement_counter(:approved_companies_count, record.application_id)
    end
  end

  after_destroy do |record|
    if record.approved?
      Application.decrement_counter(:approved_companies_count, record.application_id)
    end
  end
  
 
  def self.destroy_unpaid_application #cron job to cancel service
    companifications = Companification.find(:all)
    companifications.each do |companification|
        if !Company.find_by_id(companification.id).blank?
        plan = ApplicationPlan.find_by_id(companification.plan_id)
        if plan.application_nature == "basic"
            logger.info("basic..........")
            logger.info(plan.payment_type)
            logger.info("10 days #{10.days.from_now}")
            logger.info(plan.monthly?)
            logger.info(plan.id)
            logger.info(companification.end_at)
            if plan.payment_type == "monthly" and (companification.end_at < 10.days.from_now)
              logger.info("1111111111111111111111111111111111111111111111111")
              employees = Employee.find_all_by_company_id(companification.company_id)
              if plan.code.delete(' ').downcase.include?("ippbx")
                PortalIppbxController.new.remove_company_ippbx(companification.company_id)
              elsif plan.code.delete(' ').downcase.include?("cloud")
                PortalCloudstorageController.new.remove_company(companification.company_id)
              end
              
              employees.each do  |emp|
                logger.info("destroy employees........")
                employee_app = EmployeeApplication.find_by_employee_id_and_application_id(emp.id,companification.application_id)
                employee_app.destroy unless employee_app.blank?
                User.find_by_id(emp.user_id).update_attributes(:phone => "") if plan.code.delete(' ').downcase.include?("ippbx")
              end
              
              Order.find_by_id(companification.order_id).update_attributes(:status => "cancelled")
              addon_companifications = Companification.find_all_by_company_id_and_application_id(companification.company_id, companification.application_id)
              logger.info("Addon Deletion......")
              addon_companifications.each do  |addon_companification|
                  if !companification.plan_id == addon_companification.plan_id
                    addon_fileds = {:user_id=> current_user.id, :resource_type => "payments", :resource_id => addon_companification.payment_id, :request => params[:request], :requested_at => Time.now}
                    addon_request = UserRequest.new(addon_fileds)
                    addon_request.save
                  end
                  addon_companification.destroy
              end
            end
        else
              logger.info("addon..........")
              logger.info("Time...#{Time.now}")
              if plan.monthly? and companification.end_at < Time.now                   
                 order = Order.find_by_id(companification.order_id)
                if plan.code.delete(' ').downcase.include?("ippbx")
                PortalIppbxController.new.remove_public_number companification.company_id, order.id
              elsif plan.code.delete(' ').downcase.include?("cloud")
                  quota = order.quantity.to_i * 1024
                PortalCloudstorageController.new.decrement_quota companification.company_id, quota
              end
              
              if plan.default_employees_count > 0
                 basic_companification = Companification.find_by_application_id_and_company_id(companification.application_id, companification.company_id)
                 order = Order.find_by_id(companification.order_id)
                 old_count = basic_companification.max_employees_count
                 basic_companification.max_employees_count = old_count - order.quantity
                 basic_companification.save
              end
                                     
           end
        
        end
    end
  end
end

end
