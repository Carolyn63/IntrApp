# # RVM
# $:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"

require 'yaml'
require "bundler/capistrano"
set :bundle_flags, "--deployment --quiet --binstubs"
set :rake, 'bin/rake'

require "capistrano/ext/multistage"
set :default_stage, "staging"
set :stages, %w(staging connections)

require "lib/capistrano/recipes"

set :chmod755, "app config db lib public vendor script script/* public/disp*"

set :scm, :git
set :repository, 'git@github.com:Gera-IT/eBento.git'
set :use_sudo, false

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
default_run_options[:shell] = false

before 'deploy', :stop_backgroundrb
after "deploy", :start_backgroundrb

# New flow
after :'deploy:setup', :'thinking_sphinx:setup'
after :'deploy:create_symlink', :'thinking_sphinx:create_symlink'

after "deploy:update", :run_after_update_commands
after :'run_after_update_commands', :'thinking_sphinx:configure'

schedulers = %w{sphinx_scheduler}

task :run_after_update_commands, :roles => :web do
  run "cp #{ current_path }/config/deploy/#{ stage }/database.yml #{ current_path }/config/database.yml"
  run "cp #{ current_path }/config/deploy/#{ stage }/sphinx.yml #{ current_path }/config/sphinx.yml"
  run "cp #{ current_path }/config/deploy/#{ stage }/app_config.yml #{ current_path }/config/app_config.yml"
  run "cp #{ current_path }/config/deploy/#{ stage }/unicorn.rb #{ current_path }/config/unicorn.rb"
  run "cp #{ current_path }/config/deploy/#{ stage }/robots.txt #{ current_path }/public/robots.txt"
end

task :show_log, :roles => :web do
  run "tail -f #{current_path}/log/production.log -n 100"
end

# Thinking Sphinx
namespace :thinking_sphinx do
  task :configure, :roles => [:app] do
    rake "thinking_sphinx:configure"
  end

  task :index, :roles => [:app] do
    rake "thinking_sphinx:index"
  end

  task :start, :roles => [:app] do
    rake "thinking_sphinx:start"
  end

  task :stop, :roles => [:app] do
    rake "thinking_sphinx:stop"
  end

  task :restart, :roles => [:app] do
    rake "thinking_sphinx:restart"
  end

  task :rebuild, :roles => [:app] do
    rake "thinking_sphinx:rebuild"
  end

  task :setup do
    run "mkdir -p #{ shared_path }/db/sphinx"
  end

  task :create_symlink do
    run "ln -nfs #{ shared_path }/db/sphinx #{ current_path }/db/"
  end
end

#TODO DelayedJob started in development mode. Fixed this if you know how. DB in dev must be link to producation
task :stop_backgroundrb, :roles => :web do
  #thinking_sphinx.stop
  # run "cd #{current_path} && RAILS_ENV=production ruby script/delayed_job stop"
  schedulers.each do |scheduler|
    run "cd #{ current_path } && bundle exec ruby ./lib/schedulers/#{scheduler}.rb stop -e production -p #{ scheduler }_deamon"
  end
end

#TODO DelayedJob started in development mode. Fixed this if you know how. DB in dev must be link to producation
task :start_backgroundrb, :roles => :web do
  #symlink_sphinx_indexes
  #thinking_sphinx.configure
  # thinking_sphinx.start

  # run "cd #{current_path} && RAILS_ENV=production ruby script/delayed_job start"
  schedulers.each do |scheduler|
    run "cd #{current_path} && bundle exec ruby ./lib/schedulers/#{ scheduler }.rb start -e production -p #{ scheduler }_deamon"
  end
end

namespace :delayed_job do
  [:start, :stop].each do |t|
    desc "#{t.to_s} delayed job"
    task "#{t.to_s}", :roles => :app do
      run "cd #{ current_path } && RAILS_ENV=#{ rails_env } ruby script/delayed_job #{ t.to_s }"
    end
  end
  task :restart do
    delayed_job.stop; delayed_job.start
  end
end

def rake(*tasks)
  rake = fetch(:rake, "rake")
  rails_env = fetch(:rails_env, 'production')
  tasks.each do |t|
    run "cd #{current_path}; #{rake} RAILS_ENV=#{rails_env} #{t}"
  end
end

namespace :deploy do
  task :restart do
    unicorn.reload
    thinking_sphinx.restart
    delayed_job.restart
  end
end

namespace :seeds do
  task 'application_types' do
    run "cd #{ current_path } && RAILS_ENV=#{ rails_env } bundle exec rake seeds:application_types"
  end
end

namespace :cached_counters do
  task(:reset) { rake "cached_counters:reset" }
end
