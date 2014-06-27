class UserRequest < ActiveRecord::Base

  cattr_reader :per_page
  @@per_page = 30

  module Status
    PENDING = "pending"
    APPROVED = "approved"
    FAILED = "failed"

    ALL = [PENDING, APPROVED, FAILED]

    LIST = [
      [I18n.t('models.users_request.pending'), PENDING],
      [I18n.t('models.users_request.approved'), APPROVED],
      [I18n.t('models.users_request.failed'), FAILED]
    ]

    TO_LIST = {
      PENDING => I18n.t('models.users_request.pending'),
      APPROVED => I18n.t('models.users_request.approved'),
      FAILED => I18n.t('models.users_request.failed'),
    }
  end
  


  belongs_to :payment, :foreign_key => :resource_id
  belongs_to :user

  validates_presence_of :resource_id
  validates_presence_of :user_id
  #validates_uniqueness_of :company_id, :scope => :application_id

   # AASM
  include AASM
  aasm_column :status
  aasm_initial_state :pending
  aasm_state :pending
  aasm_state :approved
  aasm_state :failed

  aasm_event :approve do
    transitions :to => :approved, :from => [:pending]
  end
  
  aasm_event :fail do
    transitions :to => :failed, :from => [:pending]
  end



  named_scope :approved, :conditions => {:status => UserRequest::Status::APPROVED}
  named_scope :pending, :conditions => {:status => UserRequest::Status::PENDING}
  named_scope :failed, :conditions => {:status => UserRequest::Status::FAILED}
  named_scope :pending_resource_request, lambda {|resource_type|
   resource_type.blank? ? {} :  {:conditions => ["status =? and resource_type =?",UserRequest::Status::PENDING, resource_type]}
  }



end
