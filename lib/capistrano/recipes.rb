Capistrano::Configuration.instance.load do
  def run_local(command)
    `#{ command }`
  end

  namespace :delayed_job do
    task(:start) {}
    task(:stop) {}
  end

  namespace :db do
    task :pull do
      filename = "#{ deploy_to }/#{ application }-dump_#{ Time.now.to_i.to_s }-#{ rails_env }.sql"
      local_filename = File.basename(filename)
      run "cd #{ current_path } && bin/rake db:dump RAILS_ENV=#{ rails_env } > #{ filename }"
      download filename, local_filename
      run_local("bin/rake db:shell < #{ local_filename }")
    end
  end

  namespace :logs do
    task(:tail) {stream "tail -f #{shared_path}/log/#{rails_env}.log"}
    namespace(:unicorn) { task(:tail) {stream "tail -f #{shared_path}/log/unicorn.log"}}
    namespace(:delayed_job) { task(:tail) {stream "tail -f #{shared_path}/log/delayed_job.log"}}
    namespace(:sphinx) { task(:tail) {stream "tail -f #{shared_path}/log/searchd.log"}}
    #TODO nginx error, access
  end

  namespace :loops do
    task(:start) { run "if #{loops_pid_exists}; then echo 'loops already running!' ; else cd #{current_path} && RAILS_ENV=#{rails_env} bin/loops start -d #{loops_env}; fi" }
    task(:stop) { run "if #{loops_pid_exists}; then cd #{current_path} && RAILS_ENV=#{rails_env} bin/loops stop #{loops_env}; fi" }
    task(:list) { run "if #{loops_pid_exists}; then cd #{current_path} && RAILS_ENV=#{rails_env} bin/loops list #{loops_env}; fi" }
    task(:stats) { run "if #{loops_pid_exists}; then cd #{current_path} && bin/loops-memory-stats; fi"}
  end

end
