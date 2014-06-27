class AddNewFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :job_title, :string, :default => "", :null => false
    add_column :users, :city, :string, :default => "", :null => false
    add_column :users, :state, :string, :default => "", :null => false
    add_column :users, :country, :string, :default => "", :null => false
  end

  def self.down
    remove_column :users, :job_title
    remove_column :users, :city
    remove_column :users, :state
    remove_column :users, :country
  end
end
