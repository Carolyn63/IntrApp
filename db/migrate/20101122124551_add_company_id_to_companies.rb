class AddCompanyIdToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :ondeego_company_id, :integer
    add_column :companies, :is_ondeego_connect, :integer, :limit => 1, :default => 0, :null => false
  end

  def self.down
    remove_column :companies, :ondeego_company_id
    remove_column :companies, :is_ondeego_connect
  end
end
