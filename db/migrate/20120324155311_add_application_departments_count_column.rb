class AddApplicationDepartmentsCountColumn < ActiveRecord::Migration
  def self.up
    add_column :applications, :departments_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :applications, :departments_count
  end
end
