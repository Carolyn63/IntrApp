class AddOndeegoFieldToCompaniesAndEmployees < ActiveRecord::Migration
  def self.up
    add_column :companies, :country_phone_code, :string, :default => "+1"
    add_column :employees, :ondeego_email, :string
    add_column :employees, :device_nickname, :string, :null => false, :default => ""
  end

  def self.down
    remove_column :companies, :country_phone_code
    remove_column :employees, :ondeego_email
    remove_column :employees, :device_nickname
  end
end
