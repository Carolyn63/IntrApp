class AddCategoryApplicationsCountColumn < ActiveRecord::Migration
  def self.up
    add_column :categories, :applications_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :categories, :applications_count
  end
end
