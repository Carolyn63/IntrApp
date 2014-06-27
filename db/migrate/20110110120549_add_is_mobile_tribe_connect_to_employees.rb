class AddIsMobileTribeConnectToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :is_mobile_tribe_connect, :integer, :limit => 1, :default => 0, :null => false
  end

  def self.down
    remove_column :employees, :is_mobile_tribe_connect
  end
end
