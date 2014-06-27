class AddMessagesAndAttributesFieldToAudit < ActiveRecord::Migration
  def self.up
    add_column :audits, :messages, :text, :limit => 2.kilobytes
    add_column :audits, :auditable_attributes, :text
  end

  def self.down
    remove_column :audits, :messages
    remove_column :audits, :auditable_attributes
  end
end
