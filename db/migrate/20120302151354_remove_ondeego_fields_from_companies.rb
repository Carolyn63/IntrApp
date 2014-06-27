class RemoveOndeegoFieldsFromCompanies < ActiveRecord::Migration
  def self.up
    remove_column :companies, :ondeego_company_id
    remove_column :companies, :is_ondeego_connect
  end

  def self.down
    add_column :companies, :ondeego_company_id, :integer
    add_column :companies, :is_ondeego_connect, :integer, :limit => 1, :default => 0, :null => false
  end
end
