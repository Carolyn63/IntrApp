class CareateTypizations < ActiveRecord::Migration
  def self.up
    create_table :typizations do |t|
      t.belongs_to :application, :null => false
      t.belongs_to :application_type, :null => false
    end
  end

  def self.down
    drop_table :typizations
  end
end
