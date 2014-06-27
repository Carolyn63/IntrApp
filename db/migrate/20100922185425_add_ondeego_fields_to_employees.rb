class AddOndeegoFieldsToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :device_type, :string, :null => false, :default => ""
    add_column :employees, :device_os, :string, :null => false, :default => ""
    add_column :employees, :ondeego_login, :string, :null => false, :default => ""
    add_column :employees, :ondeego_password, :string, :null => false, :default => ""
  end

  def self.down
    remove_column :employees, :device_type
    remove_column :employees, :device_os
    remove_column :employees, :ondeego_login
    remove_column :employees, :ondeego_password
  end
end
