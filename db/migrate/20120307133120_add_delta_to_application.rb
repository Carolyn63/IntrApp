class AddDeltaToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :delta, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :applications, :delta
  end
end
