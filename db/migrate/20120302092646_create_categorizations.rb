class CreateCategorizations < ActiveRecord::Migration
  def self.up
    create_table :categorizations do |t|
      t.belongs_to :application, :null => false
      t.belongs_to :category, :null => false
    end
  end

  def self.down
    drop_table :categorizations
  end
end
