class CreateEmployees < ActiveRecord::Migration
  def self.up
    create_table :employees do |t|
      t.integer :user_id
      t.integer :company_id
      t.string  :status, :default => Employee::Status::PENDING, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :employees
  end
end
