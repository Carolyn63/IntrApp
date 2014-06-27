class RemoveOndeegoEmailAndRenameOndeegoPhoneInEmployees < ActiveRecord::Migration
  def self.up
    remove_column :employees, :ondeego_email
    rename_column :employees, :ondeego_phone, :phone
  end

  def self.down
    add_column :employees, :ondeego_email, :string
    rename_column :employees, :phone, :ondeego_phone
  end
end
