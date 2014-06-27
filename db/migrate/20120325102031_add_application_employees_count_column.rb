class AddApplicationEmployeesCountColumn < ActiveRecord::Migration
  def self.up
    add_column :applications, :employees_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :applications, :employees_count
  end
end
