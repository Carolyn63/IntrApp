class RemovePositionAndQualificationFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :position
    remove_column :users, :qualification
  end

  def self.down
     add_column :users, :position, :string, :null => false, :default => ""
     add_column :users, :qualification, :string, :null => false, :default => ""
  end
end
