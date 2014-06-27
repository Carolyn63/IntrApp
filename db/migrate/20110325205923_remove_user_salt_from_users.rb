class RemoveUserSaltFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :user_password_salt
  end

  def self.down
    add_column :users, :user_password_salt, :string, :null => false
  end
end
