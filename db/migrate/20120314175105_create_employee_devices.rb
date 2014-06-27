class CreateEmployeeDevices < ActiveRecord::Migration
  def self.up
    create_table :employee_devices do |t|
      t.belongs_to :employee, :null => false
      t.belongs_to :device, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :employee_devices
  end
end
