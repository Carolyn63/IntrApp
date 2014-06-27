class AddUsernameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :firstname, :string , :null => false, :default => ""
    add_column :users, :lastname, :string , :null => false, :default => ""
  end

  def self.down
    remove_column :users, :firstname
    remove_column :users, :lastname
  end
end
