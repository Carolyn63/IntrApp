class CreateDepartmentApplications < ActiveRecord::Migration
  def self.up
    create_table :department_applications do |t|
      t.belongs_to :application, :null => false
      t.belongs_to :department, :null => false
    end
  end

  def self.down
    drop_table :department_applications
  end
end
