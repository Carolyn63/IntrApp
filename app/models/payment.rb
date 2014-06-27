class Payment < ActiveRecord::Base
   has_many  :applications
   has_many :applications ,:through => :company_applications 
   has_many :user_requests, :foreign_key => :resource_id
   #after_create :send_payment_details
   
  named_scope :active_payments, lambda {|user|
    user.blank? ? {} : {:conditions => ["email = ? and (transaction_type =? or transaction_type=?)", user.email,"subscr_signup",
      "subscr_payment"]}
  }
  
  named_scope :cancelled_payments, lambda {|user|
    user.blank? ? {} : {:conditions => ["email = ? and transaction_type =?", user.email,"subscr_cancel"]}
  }
  
  named_scope :refunded_payments, lambda {|user|
    user.blank? ? {} : {:conditions => ["email = ? and transaction_type =?", user.email,"subscr_refund"]}
  }
  
  named_scope :by_payment_id, lambda {|ids|
    ids.blank? ? {} : {:conditions => ["id IN(?) and (transaction_type !=? or transaction_type !=?)", ids, "subscr_refund", "subscr_cancel"]}
  }


  def self.create_payment params
   @payment = Payment.new(params)
   success = @payment.save
   return success
  end
  
 def send_payment_details
    if self.transaction_type == "subscr_signup" # or other type (for once, topup)
      email = self.email
      user = User.find_by_email(self.email)
      plan_ids = self.plan_ids.split(",")
      application_plan_code = ""
      plan_ids.each do |id|
        application_plan = ApplicationPlan.find_by_id(id.to_i)
        application_plan_code += application_plan.code + ","
      end
      application_plan_code = application_plan_code.chop
      begin	
      Notifier.deliver_send_payment_notification(user.email, application_plan_code, user.id, user.login)
      rescue
      end
      end
  end
  
  end
