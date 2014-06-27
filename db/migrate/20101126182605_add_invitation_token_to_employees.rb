class AddInvitationTokenToEmployees < ActiveRecord::Migration
  def self.up
    add_column :users, :active, :boolean, :default => true, :null => false
    add_column :employees, :invitation_token, :string
    User.update_all("active=1")
  end

  def self.down
    remove_column :employees, :invitation_token
    remove_column :users, :active
  end
end
