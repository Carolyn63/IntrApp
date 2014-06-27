class AddApplicationTypeApplicationsCountColumn < ActiveRecord::Migration
  def self.up
    add_column :application_types, :applications_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :application_types, :applications_count
  end
end
