class CreateCompanies < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :name, :null => false, :default => ""
      t.string :address, :null => false, :default => ""
      t.string :city, :null => false, :default => ""
      t.string :phone, :null => false, :default => ""
      t.string :company_type
      t.integer :privacy, :default => Company::Privacy::PUBLIC, :null => false
      t.string :industry, :null => false, :default => ""
      t.text :description
      t.string :size, :null => false, :default => ""
      t.string :team, :null => false, :default => ""
      t.string :logo_file_name
      t.string :logo_content_type
      t.integer :logo_file_size
      t.datetime :logo_updated_at
      t.integer :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :companies
  end
end
