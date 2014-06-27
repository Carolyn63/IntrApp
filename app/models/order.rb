class Order < ActiveRecord::Base
   
  module Nature

    BASIC = "basic"
    ADDON = "addon"
    EMPLOYEE = "employee"
    ALL = [BASIC, ADDON, EMPLOYEE]

    LIST = [
      [I18n.t('models.application_plans.basic'), BASIC],
      [I18n.t('models.application_plans.addon'), ADDON],
      [I18n.t('models.application_plans.employee'), EMPLOYEE]
    ]

    TO_LIST = { BASIC => I18n.t('models.application_plans.basic'), ADDON => I18n.t('models.application_plans.addon'),EMPLOYEE => I18n.t('models.application_plans.employee')}

  end
  
  module Status
    PENDING = "pending"
    PAID = "paid"
    CANCELLED = "cancelled"
    WISHING = "whishing"

    ALL = [PENDING, PAID, CANCELLED,WISHING]

    LIST = [
      [I18n.t('models.orders.pending'), PENDING],
      [I18n.t('models.orders.paid'), PAID],
       [I18n.t('models.orders.cancelled'), CANCELLED],
       [I18n.t('models.orders.wishing'), WISHING]
    ]

    TO_LIST = {
      PENDING => I18n.t('models.orders.pending'),
      PAID => I18n.t('models.orders.paid'),
      CANCELLED => I18n.t('models.orders.cancelled'),
      WISHING => I18n.t('models.orders.wishing')
    }
    
  end


  
  include AASM
  aasm_column :status
  aasm_initial_state :pending
  aasm_state :pending
  aasm_state :paid
  aasm_state :cancelled
  aasm_state :wishing
  aasm_state :trial
  
  

  
  aasm_event :pay do
    transitions :to => :paid, :from => [:pending]
  end
  
  aasm_event :cancel do
    transitions :to => :cancelled, :from => [:pending]
  end
  
  aasm_event :whish do
    transitions :to => :wishing, :from => [:pending]
  end

  

   
  belongs_to :application
  belongs_to :application_plan ,:foreign_key => :plan_id
  has_one :companification, :dependent => :destroy
  validates_presence_of :quantity
  validates_presence_of :amount
  
  
  named_scope :active_orders, lambda {|user_id|
   user_id.blank? ? {} :  {:conditions => ["status =? and user_id =?",Order::Status::PENDING, user_id]}
  }
  
  named_scope :active_addons, lambda {|user_id, plan_id|
   user_id.blank? ? {} :  {:conditions => ["status =? and user_id =? and plan_id =? and application_nature !=?",Order::Status::PENDING, user_id, plan_id.to_i, Order::Nature::BASIC]}
  }
  
  named_scope :user_application, lambda {|user_id, application_id|
   user_id.blank? or application_id.blank? ? {} :  {:conditions => ["user_id =? and application_id =? and application_nature=? and status !=?",user_id, application_id, Order::Nature::BASIC, Order::Status::CANCELLED]}
  }
  
  named_scope :order_by_ids, lambda {|user_id, ids|
   user_id.blank? or ids.blank? ? {} :  {:conditions => ["user_id =? and plan_id IN(?)",user_id, ids]}
  }
  
  named_scope :pending_orders, lambda {|user_id|
   user_id.blank? ? {} :  {:conditions => ["user_id =? and status =?",user_id, Order::Status::PENDING]}
  }
  
  named_scope :pending_order_by_plan, lambda {|user_id, plan_id|
   (user_id.blank? or plan_id.blank?) ? {} :  {:conditions => ["user_id =? and plan_id =? and status =?",user_id, plan_id, Order::Status::PENDING]}
  }
 
  named_scope :purchased_extras, lambda {|user_id, application_id|
   (user_id.blank? or application_id.blank?) ? {} :  {:conditions => ["user_id =? and application_id =? and status !=?",user_id, application_id, Order::Status::PENDING]}
  }
  
  named_scope :active_basic, lambda {|user_id, plan_id|
   (user_id.blank? or plan_id.blank?) ? {} :  {:conditions => ["user_id =? and plan_id =? and (status =? or status =?)",user_id, plan_id, "paid", "trial"] }
  }
  
 

  def self.cart_count user_id
    
     Order.count(:all, :conditions => "status = 'pending' and user_id =#{user_id}")
  end
end
