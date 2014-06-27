set :application, 'ebento'
server '173.230.158.95', :app, :web, :db, :primary => true

set :rails_env, 'production'

set :use_rvm, true
set :rvm_ruby_string, 'ruby-1.8.7-p357@ebento'
set :rvm_type, :system

set :branch, "master"

set :user, 'ebento'

set :deploy_to, '/home/ebento/application'
set :deploy_via, :remote_cache
set :keep_releases, 3

set :unicorn_binary, "unicorn_rails"
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"

namespace :unicorn do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{ current_path } && if [ ! -f #{ unicorn_pid } ]; then bundle exec #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D ; else echo 'Unicorn already running' ; fi"
  end

  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "cd #{ current_path } && if [ -f #{ unicorn_pid } ]; then kill -s QUIT `cat #{unicorn_pid}`; else echo 'Unicorn not running' ; fi"
  end

  task(:stop) { }

  task :reload, :roles => :app, :except => { :no_release => true } do
    run "cd #{ current_path } && if [ -f #{ unicorn_pid } ]; then kill -s USR2 `cat #{ unicorn_pid }`; else echo 'Unicorn not running'; fi"
  end

  task(:restart) { reload }
end
