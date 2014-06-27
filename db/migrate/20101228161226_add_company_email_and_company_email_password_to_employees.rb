class AddCompanyEmailAndCompanyEmailPasswordToEmployees < ActiveRecord::Migration
  def self.up
    add_column :employees, :company_email, :string
    add_column :employees, :company_email_password, :string
  end

  def self.down
    remove_column :employees, :company_email
    remove_column :employees, :company_email_password
  end
end
