class AddPrivacyToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :privacy, :integer, :default => User::Privacy::PUBLIC, :null => false
  end

  def self.down
    remove_column :users, :privacy
  end
end
