class AddPerishableTokenToCompaniesAndEmployees < ActiveRecord::Migration
  def self.up
    add_column :companies, :perishable_token, :string, :null => false
    add_column :employees, :perishable_token, :string, :null => false
  end

  def self.down
    remove_column :companies, :perishable_token
    remove_column :employees, :perishable_token
  end
end
