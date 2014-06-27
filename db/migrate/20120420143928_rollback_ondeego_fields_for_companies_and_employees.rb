class RollbackOndeegoFieldsForCompaniesAndEmployees < ActiveRecord::Migration
  def self.up
    add_column :companies, :ondeego_company_id, :integer
    add_column :companies, :is_ondeego_connect, :integer, :limit => 1, :default => 0, :null => false

    add_column :employees, :ondeego_user_id, :integer
    add_column :employees, :oauth_token, :string
    add_column :employees, :oauth_secret, :string, :limit => 1024
    add_column :employees, :is_ondeego_connect, :integer, :limit => 1, :default => 0, :null => false
  end

  def self.down
    remove_column :companies, :ondeego_company_id
    remove_column :companies, :is_ondeego_connect

    remove_column :employees, :ondeego_user_id
    remove_column :employees, :oauth_token
    remove_column :employees, :oauth_secret
    remove_column :employees, :is_ondeego_connect
  end
end
