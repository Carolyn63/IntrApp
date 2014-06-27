class AddApplicationApprovedEmployeesCountCoumn < ActiveRecord::Migration
  def self.up
    add_column :applications, :approved_employees_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :applications, :approved_employees_count
  end
end
