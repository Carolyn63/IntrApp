class CreateCompanifications < ActiveRecord::Migration
  def self.up
    create_table :companifications do |t|
      t.belongs_to :application, :null => false
      t.belongs_to :company, :null => false
    end
  end

  def self.down
    drop_table :companifications
  end
end
