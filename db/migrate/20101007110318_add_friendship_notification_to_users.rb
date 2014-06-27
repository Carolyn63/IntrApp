class AddFriendshipNotificationToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :friendship_notification, :integer, :limit => 1, :default => 1, :null => false
  end

  def self.down
    remove_column :users, :friendship_notification
  end
end
