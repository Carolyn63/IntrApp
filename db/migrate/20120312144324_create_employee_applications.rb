class CreateEmployeeApplications < ActiveRecord::Migration
  def self.up
    create_table :employee_applications do |t|
      t.belongs_to :application, :null => false
      t.belongs_to :employee, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :employee_applications
  end
end
