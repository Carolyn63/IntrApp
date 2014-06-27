class AddStatusAndRequestedAtToCompanification < ActiveRecord::Migration
  def self.up
    add_column :companifications, :status, :string, :default => 'approved', :null => false
    add_column :companifications, :requested_at, :datetime
  end

  def self.down
    remove_column :companifications, :status
    remove_column :companifications, :requested_at
  end
end
