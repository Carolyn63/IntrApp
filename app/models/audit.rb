class Audit < ActiveRecord::Base

  belongs_to :auditable, :polymorphic => true
  
  belongs_to :parent_audit, :class_name => "Audit", :foreign_key => :parent_id
  has_many   :associations_audits, :class_name => "Audit", :foreign_key => :parent_id

  serialize :description
  serialize :comment
  serialize :auditable_attributes
  serialize :messages

  by_whatever

  named_scope :by_all_associations_audits, lambda { |audit|
    audit.blank? ? {} : {:conditions => ["parent_id IN(?)", audit.associations_audits_ids_with_self], :order => "id DESC"}
  }

  module Statuses
    FAILED = 0
    SUCCESS = 1

    LIST = [
      [I18n.t('models.audit.success'), SUCCESS],
      [I18n.t('models.audit.failed'), FAILED]
    ]
    TO_LIST = {
      SUCCESS => I18n.t('models.audit.success'),
      FAILED => I18n.t('models.audit.failed')
    }
  end

  module Types
    EMPLOYEE = "Employee"
    COMPANY = "Company"
    USER = "User"
    
    LIST = [
      [USER, USER],
      [COMPANY, COMPANY],
      [EMPLOYEE, EMPLOYEE]
    ]
  end

  module ErrorsTypes
    APPCENTRAL = "appcentral"
    SOGO = "sogo"
    MOBILE_TRIBE = "mobile_tribe"
    PORTAL = "portal"
  end


  def associations_audits_ids_with_self
    self.associations_audits.inject([self.id]) {|ids, association| ids << association.id; ids}
  end

  def success?
    self.status == Audit::Statuses::SUCCESS
  end

  def to_html(attr = :messages)
    self[attr.to_sym].is_a?(Array) ? self[attr.to_sym].join("<br/> ")  : self[attr.to_sym].to_yaml.sub(/^---\s*/m, "").gsub(/\n/, "<br/> ").gsub(/\s/, "&nbsp;")
  end

  def deliver_audit_message(emails)
     Notifier.deliver_audit_message(emails, self)
  end
end
