class EmployeeApplication < ActiveRecord::Base

	cattr_reader :per_page
	@@per_page = 30

	module Status
		PENDING = "pending"
		APPROVED = "approved"
		REJECTED = "rejected"

		ALL = [PENDING, APPROVED, REJECTED]

		LIST = [
			[I18n.t('models.companification.approved'), APPROVED],
			[I18n.t('models.companification.pending'), PENDING],
			[I18n.t('models.companification.rejected'), REJECTED]
		]

		TO_LIST = {
			PENDING => I18n.t('models.companification.pending'),
			APPROVED => I18n.t('models.companification.approved'),
			REJECTED => I18n.t('models.companification.rejected')
		}
	end

	module Assign
		BY_CA = 0
		BY_EMP = 1
		ALL = [BY_CA,BY_EMP]
	end

	belongs_to :application#, :counter_cache => :employees_count
	belongs_to :employee
	has_one :company, :through => :employee, :foreign_key => :company_id

	validates_presence_of :application
	validates_presence_of :employee
	validates_uniqueness_of :employee_id, :scope => [:application_id]

		# AASM
	include AASM
	aasm_column :status
	aasm_initial_state :approved
	aasm_state :pending, :enter => :update_requested_at
	aasm_state :approved
	aasm_state :rejected

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
	named_scope :by_employee_ids, lambda {|ids, application_id|
	ids.blank? ? {} : {:conditions => ["employee_id NOT IN(?) and application_id =?", ids, application_id]} }

	#employees_count

	after_create do |record|
		if record.approved?
			Application.increment_counter(:approved_employees_count, record.application_id)
			application  =  Application.find_by_id(record.application_id)
			employee = Employee.find_by_id(record.employee_id)
			companification = Companification.find_by_company_id_and_plan_id(employee.company_id, application.basic_plan.id)
			Companification.decrement_counter(:max_employees_count, companification.id) if record.assigned_by == EmployeeApplication::Assign::BY_CA
			
		end
	end

	after_update do |record|
		if record.status_changed? && record.approved?
			Application.increment_counter(:approved_employees_count, record.application_id)
		end
	end

	after_destroy do |record|
		if record.approved?
			Application.decrement_counter(:approved_employees_count, record.application_id)
		end
	end
  
	before_destroy do |record|
		if record.employee_id=="" # added by jhlee on 20120611
			next
		end

### assigned my employees but deleted others
###record.employee_id: 381 (NINO's)

		if record.approved?
			logger.info "record.employee_id: #{record.employee_id}"
			application  =  Application.find_by_id(record.application_id)
			employee = Employee.find_by_id(record.employee_id)
			companification = Companification.find_by_company_id_and_plan_id(employee.company_id, application.basic_plan.id)
			Companification.increment_counter(:max_employees_count, companification.id) if record.assigned_by == EmployeeApplication::Assign::BY_CA
		end
	end


	protected

	def update_requested_at
		self.requested_at = Time.now
	end

	end