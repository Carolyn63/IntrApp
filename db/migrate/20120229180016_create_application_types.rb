class CreateApplicationTypes < ActiveRecord::Migration
  def self.up
    create_table :application_types do |t|
      t.string :name, :null => false
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :application_types
  end
end
