class CreateApplications < ActiveRecord::Migration
  def self.up
    create_table :applications do |t|
      t.string :name, :null => false
      t.string :logo
      t.text :description
      t.float :price
      t.string :provider
      t.string :external_url
      t.string :bin_file
      t.boolean :active, :default => true, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :applications
  end
end
