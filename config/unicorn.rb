# -*- encoding : utf-8 -*-
rails_env = ENV['RAILS_ENV'] || 'production'
deploy_to    = "/home/pelesend/application"
shared_path  = "#{ deploy_to }/shared"
current_path = "#{ deploy_to }/current"

worker_processes (rails_env == 'production' ? 3 : 1)
pid_file     = "#{shared_path}/pids/unicorn.pid"
old_pid      = "#{pid_file}.oldbin"

pid pid_file
stderr_path File.join(current_path, 'log', 'unicorn.log')

listen 8081
preload_app true
timeout 30

if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "#{ current_path }/Gemfile"
end

before_fork do |server, worker|
  defined?(ActiveRecord::Base) && ActiveRecord::Base.connection.disconnect!
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end
