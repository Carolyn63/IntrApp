class DropApplicationActiveAttribute < ActiveRecord::Migration
  def self.up
    remove_column :applications, :active
  end

  def self.down
    add_column :applications, :active, :boolean, :default => true, :null => false
  end
end
