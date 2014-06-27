class AddFriendshipIdToFriendships < ActiveRecord::Migration
  def self.up
    add_column :friendships, :friendship_id, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :friendships, :friendship_id
  end
end
