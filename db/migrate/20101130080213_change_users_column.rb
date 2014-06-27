class ChangeUsersColumn < ActiveRecord::Migration
  def self.up
    rename_column :users, :clarification, :qualification
  end

  def self.down
    rename_column :users, :qualification, :clarification
  end
end
