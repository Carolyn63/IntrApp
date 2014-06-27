class AddPublishedAtToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :published_at, :datetime
  end

  def self.down
    remove_column :employees, :published_at
  end
end
