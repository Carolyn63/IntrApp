class AddAndRemoveToEmployees < ActiveRecord::Migration
  def self.up
    remove_column :employees, :device_nickname
    remove_column :employees, :ondeego_country_phone_code
    remove_column :employees, :device_type
    remove_column :employees, :device_os
    remove_column :employees, :ondeego_login
    remove_column :employees, :ondeego_password

    add_column :employees, :job_title, :string, :default => "", :null => false
    add_column :employees, :ondeego_user_id, :integer
    add_column :employees, :oauth_token, :string
    add_column :employees, :oauth_secret, :string, :limit => 1024
    add_column :employees, :is_ondeego_connect, :integer, :limit => 1, :default => 0, :null => false
  end

  def self.down
    add_column :employees, :device_nickname, :string, :null => false, :default => ""
    add_column :employees, :ondeego_country_phone_code, :string, :default => "+1"
    add_column :employees, :device_type, :string, :null => false, :default => ""
    add_column :employees, :device_os, :string, :null => false, :default => ""
    add_column :employees, :ondeego_login, :string, :null => false, :default => ""
    add_column :employees, :ondeego_password, :string, :null => false, :default => ""

    remove_column :employees, :job_title
    remove_column :employees, :ondeego_user_id
    remove_column :employees, :oauth_token
    remove_column :employees, :oauth_secret
    remove_column :employees, :is_ondeego_connect
  end
end
