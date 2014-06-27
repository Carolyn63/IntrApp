class ChangeDeviceDesctiption < ActiveRecord::Migration
  def self.up
    change_column :devices, :description, :text, :default => ''
  end

  def self.down
    change_column :devices, :description, :text, :default => nil
  end
end
