namespace :db do
  desc "Dump the database to standard output. Pass a TABLE_NAME environment variable to dump a single table"
  task :dump do
    require 'yaml'
    config = YAML.load_file(File.join(Rails.root,'config','database.yml'))[Rails.env]
    table_name = ENV['TABLE_NAME']

    case config["adapter"]
    when /^mysql/
      args = {
        'host'      => '--host',
        'port'      => '--port',
        'socket'    => '--socket',
        'username'  => '--user',
        'encoding'  => '--default-character-set',
        'password'  => '--password'
      }.map { |opt, arg| "#{arg}=#{config[opt]}" if config[opt] }.compact
      args << config['database']
      args << table_name unless table_name.blank?

      exec('mysqldump', *args)

    when "postgresql"
      ENV['PGUSER']     = config["username"] if config["username"]
      ENV['PGHOST']     = config["host"] if config["host"]
      ENV['PGPORT']     = config["port"].to_s if config["port"]
      ENV['PGPASSWORD'] = config["password"].to_s if config["password"]
      if table_name.blank?
        exec('pg_dump', config["database"])
      else
        exec('pg_dump', '-t', table_name, config["database"])
      end

    when "sqlite"
      raise 'Table dumping not supported with sqlite... yet' unless table_name.blank?
      exec('sqlite', config["database"], '.dump')

    when "sqlite3"
      raise 'Table dumping not supported with sqlite... yet' unless table_name.blank?
      exec('sqlite3', config['database'], '.dump')
    else
      abort "Don't know how to dump #{config['database']}."
    end
  end

  desc 'Launches the database shell using the values defined in config/database.yml'
  task :shell do
    if Rails.version > '3'
      exec 'rails', 'dbconsole', '--include-password'
    else
      exec File.join(Rails.root, 'script', 'dbconsole'), '--include-password'
    end
  end
end

namespace :db do
  task :build do
    [
    :'db:drop', :'db:create',
    :'db:load:dump',
    :'db:migrate',
    :'ts:config', :'ts:index',
    :'db:populate'].each do |task_name|#, :'db:test:prepare']
      Rake::Task[task_name].invoke rescue nil
    end
  end

  task :populate do
    # require "active_record"
    # ActiveRecord::Base.connection.reconnect!
    [
    # :'ts:config', :'ts:index',
    :'db:seed' ].each do |task_name|#, :'db:test:prepare']
      puts `bin/rake #{ task_name }`
      # Rake::Task[task_name].invoke # rescue nil
    end
  end
end
