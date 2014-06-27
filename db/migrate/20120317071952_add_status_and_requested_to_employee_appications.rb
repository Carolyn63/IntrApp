class AddStatusAndRequestedToEmployeeAppications < ActiveRecord::Migration
  def self.up
    add_column :employee_applications, :status, :string, :default => 'approved', :null => false
    add_column :employee_applications, :requested_at, :datetime
  end

  def self.down
    remove_column :employee_applications, :status
    remove_column :employee_applications, :requested_at
  end
end
