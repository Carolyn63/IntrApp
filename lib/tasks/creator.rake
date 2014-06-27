require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'faker'

require 'rubygems'

namespace :creator do
  desc "Create admin"
  task(:admin) do
    require "#{Rails.root}/config/environment.rb"
    user = User.new(:email => "admin@ebento.com",
                    :firstname => "admin",
                    :lastname => "admin",
                    :login => "ebentoadmin",
                    :password => "ebento@123456",
                    :password_confirmation => "ebento@123456",
                    :role => User::Role::ADMIN)
   user.mobile_tribe_create = true
   user.save
  end

  desc "Create MT admin"
  task(:mt_admin) do
    require "#{Rails.root}/config/environment.rb"
    user = User.new(:email => "testadmin@ebento.com",
                    :firstname => "mt_admin",
                    :lastname => "mt_admin",
                    :login => "mtadmin",
                    :password => "mt@123456",
                    :password_confirmation => "mt@123456")
   user.save
  end

  desc "Create MT contact list"
  task(:mt_contact_list) do
    require "#{Rails.root}/config/environment.rb"
    set_property( :use_ondeego, false )
    admin = User.find_by_email("testadmin@ebento.com")
    company = Company.create!(:user_id => admin.id,
                   :name => "MT Company",
                   :address => "USA",
                   :city => "New Your",
                   :phone => "111111111",
                   :company_type => "Parther",
                   :privacy => Company::Privacy::PUBLIC,
                   :industry => "IT",
                   :size => "Big",
                   :description => "blabblabblabblab",
                   :team => "MT team",
                   :country_phone_code => "+1")
    Employee.create!(:user_id => admin.id,
                    :company_id => company.id,
                    :device_type => "iPhone",
                    :device_os => "2.0",
                    :ondeego_login => "mtadmin",
                    :ondeego_password => "mtadmin123456",
                    :device_nickname => "mtadmin",
                    :ondeego_country_phone_code => "+1",
                    :ondeego_phone => "12345678")
    (1..10).each do |index|
      user = User.create!(:email => "test_mt#{index}@ebento.com",
                         :firstname => "test_mt#{index}",
                         :lastname => "test_mt#{index}",
                         :login => "test_mt#{index}",
                         :password => "mt#{index}@123456",
                         :password_confirmation => "mt#{index}@123456")
      Employee.create!(:user_id => user.id,
                     :company_id => company.id,
                     :device_type => "iPhone",
                     :device_os => "2.0",
                     :ondeego_login => "mtuser#{index}",
                     :ondeego_password => "mtuser#{index}",
                     :device_nickname => "mtuser#{index}",
                     :ondeego_country_phone_code => "+1",
                     :ondeego_phone => "12345678")
    end
  end

  desc "Create MT friends"
  task(:mt_friends) do
    require "#{Rails.root}/config/environment.rb"
    set_property( :use_ondeego, false )
    admin = User.find_by_email("testadmin@ebento.com")
    (1..5).each do |index|
      user = User.find_by_email("test_mt#{index}@ebento.com")
      unless user.blank?
        Friendship.create_friendship admin, user
      end
    end
    Friendship.accept_friendships admin.friendships.map(&:id)
  end

  task(:clear_mt_stuff) do
    require "#{Rails.root}/config/environment.rb"
    set_property( :use_ondeego, false )
    admin = User.find_by_email("testadmin@ebento.com")
    admin.destroy
    (1..10).each do |index|
      user = User.find_by_email("test_mt#{index}@ebento.com")
      user.destroy
    end
  end


  desc "Create MT contact list"
  task(:clear_companies) do
    require "#{Rails.root}/config/environment.rb"
    set_property( :use_ondeego, false )
    Company.destroy_all
  end

  desc "Update passwords"
  task(:update_passwords) do
    require "#{Rails.root}/config/environment.rb"
    User.all.each do |u|
      password = u.user_password.blank? ? "123456" : u.user_password
      u.update_attributes(:password => password, :password_confirmation => password)
    end
  end

  desc "Load Help system URLs"
  task(:help_urls) do
    require "#{Rails.root}/config/environment.rb"
    puts "Load Help system URLs..."
    [
      ["Registration page", "/signup", "About+registration+settings"],
      ["Welcome to eBento (Dashboard)", "/users/:id/dashboard", "About+the+Home+page"],
      ["Contact Us (Contact Support)", "/support/contact_us", "Request+support"],
      ["People (Find People)", "/users", "About+the+People+page"],
      ["Companies (Find Companies)", "/users/:id/companies", "About+the+Companies+page"],
      ["Coworkers (My Coworkers)", "/users/:id/contacts", "About+the+Coworkers+page"],
      ["Application (My Applications)", "/users/:id/applications", "About+the+Application+page"],
      ["Manage > Personal Profile (My eBento Profile)", "/users/:id/edit", "Edit+your+profile"],
      ["Manage > Create Company (Create Company)", "/companies/new", "Create+company+profile"],
      ["Company Owner Information", "/companies/new?owner=1", "Provide+company+owner+information"],
      ["Manage > Employees > Create Employee (Create New Employee)", "/companies/:id/employees/new", "Create+new+employee"],
      ["Manage > Employees > Edit Profile (Edit Employee Profile)", "/companies/:id/employees/:id/edit?status=active", "Edit+employee+profiles"],
      ["Manage > Employees > Active Employees (Existing Employees)", "/companies/:id/employees", "Manage+active+employees"],
      ["Manage > Employees > Pending Employees (Existing Employees)", "/companies/:id/employees?status=pending", "Manage+pending+employees"],
      ["Manage > Employees > Rejected Employees (Existing Employees)", "/companies/:id/employees?status=rejected", "Manage+rejected+employees"],
      ["Manage Friends (My Friends)", "/users/:id/friends", "Manage+friends"],
      ["Manage > Friendship Requests (Received)", "/users/:id/friendships/incoming_requests", "Manage+received+requests"],
      ["Manage > Friendship Requests (Sent)", "/users/:id/friendships/outcoming_requests", "Manage+sent+requests"],
      ["Manage > Friendship Requests (Rejected)", "/users/:id/friendships/rejected_outcoming_requests", "Manage+rejected+requests"],
      ["Manage > Invitations (Active)", "/users/:id/employers?status=active", "Manage+active+employer"],
      ["Manage > Invitations (Pending)", "/users/:id/employers", "Manage+pending+employer"],
      ["Manage > Invitations (Rejected)", "/users/:id/employers?status=rejected", "Manage+rejected+employer"],
      ["Person Profile", "/users/:id", "About+the+Profile+page"],
      ["Company Employee List", "/companies/:id/profile", "Display+employee+list"],
      ["Add as Employee (Generate Employee Accounts)", "/employees/new_recruit", "Add+employee"],
      ["Company profile", "/companies/:id", "Edit+company+profile"],
    ].each do |row|
      HelpUrl.create!(:name => row[0], :portal_url => row[1], :help_url => "#{property(:help_system_link)}/#{row[2]}")
    end
    puts "Finished load help url"
  end



#  desc "Load fake db data"
#  task(:load_fake_db) do
#    require "#{Rails.root}/config/environment.rb"
#    set_property( :use_ondeego, false )
#    set_property( :use_mobile_tribe, false )
#    PRIVACY = [0,1]
#    2.times do
#      User.new(:email => Faker::Internet.email,
#               :firstname => Faker::Name.first_name,
#               :lastname => Faker::Name.last_name,
#               :password => "123456",
#               :password_confirmation => "123456",
#               :login => Faker::Internet.user_name,
#               :privacy => PRIVACY.rand,
#               :address => Faker::Address.street_address,
#               :city => Faker::Address.city,
#               :state => Faker::Address.us_state,
#               :country => "USA",
#               :phone => Faker.numerify("########"),
#               :cellphone => Faker.numerify("########"),
#               :site => Faker::Internet.domain_name,
#               :position =>
#               :qualification =>
#               :job_title =>
#               :age => (18..70).rand,
#               :sex => ["Male","Fimale"].rand,
#               :description => Faker::Lorem.paragraph)
#    end
#  end


end
