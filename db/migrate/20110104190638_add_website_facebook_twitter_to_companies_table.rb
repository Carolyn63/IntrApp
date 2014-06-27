class AddWebsiteFacebookTwitterToCompaniesTable < ActiveRecord::Migration
  def self.up
    add_column :companies, :website, :string, :default => "", :null => false
    add_column :companies, :twitter, :string, :default => "", :null => false
    add_column :companies, :facebook, :string, :default => "", :null => false
  end

  def self.down
    remove_column :companies, :website
    remove_column :companies, :twitter
    remove_column :companies, :facebook
  end
end
