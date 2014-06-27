class LoadInitialHelpUrls < ActiveRecord::Migration
  def self.up
    Rake::Task['creator:help_urls'].invoke
  end

  def self.down
  end
end
