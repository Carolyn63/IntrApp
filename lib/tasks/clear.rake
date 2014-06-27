require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'rubygems'

#rake clear:all RAILS_ENV=production
namespace :clear do
  desc "Clear all"
  task(:all) do
    require "#{Rails.root}/config/environment.rb"
    puts "Begin reset database..."
    %w{users companies employees friendships departments audits}.each do |table|
      ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
    end
    puts "Database successful reseted"
    puts "Create admin..."
    user = User.new(:email => "admin@ebento.com",
                    :firstname => "admin",
                    :lastname => "admin",
                    :login => "ebentoadmin",
                    :password => "ebento@123456",
                    :password_confirmation => "ebento@123456",
                    :role => User::Role::ADMIN)
    user.mobile_tribe_create = true
    user.save
    puts "Admin successful created. Login/pass: ebentoadmin/ebento@123456"
    
    puts "Rebuild search index..."
    `rake thinking_sphinx:rebuild RAILS_ENV=#{RAILS_ENV}`
    puts "Rebuild search index finished"
  end

  desc "Clear sogo and email accounts"
  task(:sogo) do
    require "#{Rails.root}/config/environment.rb"
    puts "Begin reset sogo and mail database..."
    Services::Sogo::Wrapper.new.delete_all_user(:domain => "@#{property(:sogo_email_domaim)}")
    puts "Database successful reseted"
    if property(:sogo_email_domaim) == "ebento.net"
      begin
        puts "Begin create account for outcoming emails..."
        Services::Sogo::Wrapper.new.create_user(:email => "noreply@ebento.net",
                                  :password => "el3ento2011",
                                  :crypted_password => Tools::MysqlEncrypt.mysql_encrypt("el3ento2011"))
      rescue Services::Sogo::Errors::OnWrapperError => e
        puts "#{e.to_s}"
      end
    end
  end

end
