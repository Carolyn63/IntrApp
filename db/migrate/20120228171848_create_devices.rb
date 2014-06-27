class CreateDevices < ActiveRecord::Migration
  def self.up
    create_table :devices do |t|
      t.string :name, :null => false
      t.text :description, :null => false
    end
  end

  def self.down
    drop_table :devices
  end
end
