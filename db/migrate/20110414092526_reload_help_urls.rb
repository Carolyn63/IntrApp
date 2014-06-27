class ReloadHelpUrls < ActiveRecord::Migration
  def self.up
    HelpUrl.destroy_all
    Rake::Task['creator:help_urls'].invoke
  end

  def self.down
  end
end
