class AddCountryPhoneCodeAndPhoneToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :ondeego_country_phone_code, :string, :default => "+1"
    add_column :employees, :ondeego_phone, :string
  end

  def self.down
    remove_column :employees, :ondeego_country_phone_code
    remove_column :employees, :ondeego_phone
  end
end
