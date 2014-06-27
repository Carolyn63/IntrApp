class CreateHelpUrls < ActiveRecord::Migration
  def self.up
    create_table :help_urls do |t|
      t.string :name,            :null => false, :default => ""
      t.string :portal_url,      :null => false, :default => ""
      t.string :help_url,        :null => false, :default => ""
      t.string :action_name,     :null => false, :default => ""
      t.string :controller_name, :null => false, :default => ""
      t.string :url_params,      :null => false, :default => ""
      t.timestamps
    end
  end

  def self.down
    drop_table :help_urls
  end
end
