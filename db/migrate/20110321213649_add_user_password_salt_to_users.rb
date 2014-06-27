class AddUserPasswordSaltToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :user_password_salt, :string, :null => false
  end

  def self.down
    remove_column :users, :user_password_salt
  end
end
