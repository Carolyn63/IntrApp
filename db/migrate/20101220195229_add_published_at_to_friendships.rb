class AddPublishedAtToFriendships < ActiveRecord::Migration
  def self.up
    add_column :friendships, :published_at, :datetime
  end

  def self.down
    remove_column :friendships, :published_at
  end
end
