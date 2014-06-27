class AddApplicationApprovedCompaniesCountColumn < ActiveRecord::Migration
  def self.up
    add_column :applications, :approved_companies_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :applications, :approved_companies_count
  end
end
