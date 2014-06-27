class AddMobileTribeLoginAndPasswordToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :mobile_tribe_login, :string, :null => false, :default => ""
    add_column :users, :mobile_tribe_password, :string, :null => false, :default => ""
  end

  def self.down
    remove_column :users, :mobile_tribe_login
    remove_column :users, :mobile_tribe_password
  end
end
