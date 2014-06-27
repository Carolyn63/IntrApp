class ApplicationPlan < ActiveRecord::Base
  module Status
    ACTIVE = 1
    DEACTIVATED = 0

    ALL = [ACTIVE, DEACTIVATED]

    LIST = [
      ['Active', ACTIVE],
      ['Deactivated', DEACTIVATED]
    ]

    TO_LIST = { ACTIVE => 'Active', DEACTIVATED => 'Deactivated' }
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

  module Nature

    BASIC = "basic"
    ADDON = "addon"
    EMPLOYEE = "employee"
    ALL = [BASIC, ADDON, EMPLOYEE]

    LIST = [
      ["Basic", BASIC],
      ["Addon", ADDON],
      ["Employee", EMPLOYEE]
    ]

    TO_LIST = { BASIC => "Basic", ADDON => "Addon",EMPLOYEE => "Employee"}

  end
  

  include AASM

  aasm_column :application_nature
  aasm_state :basic
  aasm_state :addon
  aasm_state :employee

  belongs_to :applications, :dependent => :destroy

  has_one :active_order , :class_name => "Order", :conditions => {:status => Order::Status::PAID}, :foreign_key => :plan_id
  has_many :orders, :foreign_key => :plan_id
  has_one :companification, :foreign_key => :plan_id
  #has_one :basic_companification, :class_name => "Companification", :conditions => {:application_nature => Companification::Status::}, :foreign_key => :plan_id
  named_scope :active_plans, lambda {|application_id|
  application_id.blank? ? {} :  {:conditions => ["active =? and application_id =? and application_nature !=?",ApplicationPlan::Status::ACTIVE, application_id, ApplicationPlan::Nature::BASIC]}
  }

  named_scope :basic_plan, lambda {|plan_id|
  plan_id.blank? ? {} :  {:conditions => ["active =? and id =? and application_nature =?",ApplicationPlan::Status::ACTIVE, plan_id, ApplicationPlan::Nature::BASIC]}
  }

  def self.plan_id id
    return ApplicationPlan.find_by_application_id_and_application_nature(id, 'application').id
  end

  def company_request(company)
    self.companifications.find_by_c_tyompany_id(company.id)
  end
  
  def monthly?
    self.payment_type == "monthly"
  end
  def free?
    self.payment_type == "free"
  end
    def once?
    self.payment_type == "once"
  end
end
