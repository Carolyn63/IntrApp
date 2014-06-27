class AddRoleAndStatusToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :role, :integer, :default => User::Role::USER, :null => false
    add_column :users, :status, :integer, :default => User::Status::ACTIVE, :null => false
  end

  def self.down
    remove_column :users, :role
    remove_column :users, :status
  end
end
