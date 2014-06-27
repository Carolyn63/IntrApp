class AddStatusToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :status, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :applications, :status
  end
end
