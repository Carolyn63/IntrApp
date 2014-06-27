class ExtendUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :address, :string, :null => false, :default => ""
    add_column :users, :phone, :string, :null => false, :default => ""
    add_column :users, :cellphone, :string, :null => false, :default => ""
    add_column :users, :position, :string, :null => false, :default => ""
    add_column :users, :age, :string, :null => false, :default => ""
    add_column :users, :sex, :string, :null => false, :default => ""
    add_column :users, :site, :string, :null => false, :default => ""
    add_column :users, :clarification, :string, :null => false, :default => ""
    add_column :users, :description, :text
  end

  def self.down
    remove_column :users, :address
    remove_column :users, :phone
    remove_column :users, :cellphone
    remove_column :users, :position
    remove_column :users, :age
    remove_column :users, :sex
    remove_column :users, :site
    remove_column :users, :clarification
    remove_column :users, :description
  end
end
