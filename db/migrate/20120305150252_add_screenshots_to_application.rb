class AddScreenshotsToApplication < ActiveRecord::Migration
  def self.up
    add_column :applications, :screenshot0, :string
    add_column :applications, :screenshot1, :string
    add_column :applications, :screenshot2, :string
  end

  def self.down
    remove_column :applications, :screenshot2
    remove_column :applications, :screenshot1
    remove_column :applications, :screenshot0
  end
end
