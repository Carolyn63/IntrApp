class CreateDevicefications < ActiveRecord::Migration
  def self.up
    create_table :devicefications do |t|
      t.belongs_to :application, :null => false
      t.belongs_to :device, :null => false
    end
  end

  def self.down
    drop_table :devicefications
  end
end
