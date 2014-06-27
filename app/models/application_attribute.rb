class ApplicationAttribute < ActiveRecord::Base
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

  module Payment

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
      [I18n.t('models.application_attributes.basic'), BASIC],
      [I18n.t('models.application_attributes.addon'), ADDON],
      [I18n.t('models.application_attributes.employee'), EMPLOYEE]
    ]

    TO_LIST = { BASIC => I18n.t('models.application_attributes.basic'), ADDON => I18n.t('models.application_attributes.addon'),EMPLOYEE => I18n.t('models.application_attributes.employee')}

  end
  include AASM
  
  aasm_column :payment_type
  aasm_state :free
  aasm_state :once
  aasm_state :monthly
  
  
  aasm_column :application_nature
  aasm_state :basic
  aasm_state :addon
  aasm_state :employee

  belongs_to :applications, :dependent => :destroy, :foreign_key => :application_id
  has_many :companifications, :foreign_key => :attribute_id
  
  
  has_one :active_order , :class_name => "Order", :conditions => {:status => Order::Status::PAID}, :foreign_key => :attribute_id
  has_many :orders, :foreign_key => :attribute_id
  named_scope :active_attributes, lambda {|application_id|
  application_id.blank? ? {} :  {:conditions => ["active =? and application_id =? and application_nature !=?",ApplicationAttribute::Status::ACTIVE, application_id, ApplicationAttribute::Nature::BASIC]}
  }

  def self.attribute_id id
    return ApplicationAttribute.find_by_application_id_and_application_nature(id, 'application').id
  end
end
