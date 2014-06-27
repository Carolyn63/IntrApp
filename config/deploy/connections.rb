set :application, 'ebento'
# server 'connections.pelesend.com', :app, :db, :web, :primary => false
server '10.2.1.110', :app, :db, :web, :primary => true
set :user, :gera

set :rails_env, 'production'

set :use_rvm, true
set :rvm_ruby_string, 'ruby-1.8.7-p358@connections'
set :rvm_type, :system

set :branch, "master"

set :user, 'gera'

set :deploy_to, '/home/gera/application/connections'

set :deploy_via, :copy  #:remote_cache
set :copy_strategy, :export

set :keep_releases, 1

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

# GIT
depend :remote, :command, :git

# ImageMagick
# depend :remote, :deb, 'libmagick9-dev', '3'

# MySQL Client
depend :remote, :command, :mysql
depend :remote, :deb, 'libmysql-ruby', '2.8' #.2-1'
depend :remote, :deb, 'libmysqlclient-dev', '5.1' #.61-0ubuntu0.10.04.1'

# Sphinx
depend :remote, :command, :indexer
# depend :remote, :command, :usr/local/bin/searchd

# NGinx
# depend :remote, :deb, '', ''
