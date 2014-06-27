class RemoveOndeegoFieldsFromEmployees < ActiveRecord::Migration
  def self.up
    remove_column :employees, :ondeego_user_id
    remove_column :employees, :oauth_token
    remove_column :employees, :oauth_secret
    remove_column :employees, :is_ondeego_connect
  end

  def self.down
    add_column :employees, :ondeego_user_id, :integer
    add_column :employees, :oauth_token, :string
    add_column :employees, :oauth_secret, :string, :limit => 1024
    add_column :employees, :is_ondeego_connect, :integer, :limit => 1, :default => 0, :null => false
  end
end
