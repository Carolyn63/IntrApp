class AddDeviceApplicationsCountColumn < ActiveRecord::Migration
  def self.up
    add_column :devices, :applications_count, :integer, :null => false, :default => false
  end

  def self.down
    remove_column :devices, :applications_count
  end
end
