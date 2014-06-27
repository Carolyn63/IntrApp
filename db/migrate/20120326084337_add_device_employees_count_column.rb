class AddDeviceEmployeesCountColumn < ActiveRecord::Migration
  def self.up
    add_column :devices, :employees_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :devices, :employees_count
  end
end
