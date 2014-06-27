require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'faker'

require 'rubygems'

namespace :db do
  desc "Load fake db data"
  task(:load_fake_db) do
    require "#{Rails.root}/config/environment.rb"
     JOB_TITLE = ["Team Leader", "Engineering Technician", "Accountant", "Payroll Manager",
                  "Administrative Assistant", "Technical Analyst", "Systems Manager", "Application Engineer",
                  "Auditor", "Branch Manager", "Courier", "Director", "Driver", "Facilities Manager",
                  "Technical Services Manage", "Sales Person", "Software Configuration Manager",
                  "Recruiting Manager", "Physician Assistant", "Office Clerk", "Librarian",
                  "Information Technology Manager"]
    POSITION = ["Director", "Secratary", "Manager", "Assistant", "Engineering Services Manager", "Administrative Assistant"]
    PRIVACY = [0,1]
    #90%  status Active
    USER_COUNT = 1000
    COMPANY_COUNT_PER_USER = 3
    FRIENDS = 50
    STATUSES = Employee::Status::ALL + [Employee::Status::ACTIVE] * 2
    set_property( :use_ondeego, false )
    set_property( :use_mobile_tribe, false )
    puts "Users creating ..."
    USER_COUNT.times do
      User.new(:email => Faker::Internet.email,
               :firstname => Faker::Name.first_name,
               :lastname => Faker::Name.last_name,
               :password => "123456",
               :password_confirmation => "123456",
               :login => Faker::Internet.user_name,
               :privacy => PRIVACY.rand,
               :address => Faker::Address.street_address,
               :city => Faker::Address.city,
               :state => Faker::Address.us_state,
               :country => "USA",
               :phone => Faker.numerify("########"),
               :cellphone => Faker.numerify("########"),
               :site => "http://#{Faker::Internet.domain_name}",
               :position => POSITION.rand,
               :qualification => Faker::Lorem.sentences,
               :job_title => JOB_TITLE.rand,
               :age => (18..70).to_a.rand,
               :sex => ["Male","Fimale"].rand,
               :description => Faker::Lorem.paragraph).save
    end
    @users = User.all
    @users_ids = User.all.map(&:id)
    puts "Users #{@users_ids.size} created"
    puts "Companies creating..."
    @users.each do |u|
      COMPANY_COUNT_PER_USER.times do
        company = Company.new(:user_id => u.id,
                          :name => Faker::Company.name,
                          :address => Faker::Address.street_address,
                          :city => Faker::Address.city,
                          :phone => Faker.numerify("########"),
                          :company_type => Faker::Company.catch_phrase,
                          :industry => Faker::Company.bs,
                          :description => Faker::Lorem.paragraph,
                          :size => ["Large", "Small", "Big"].rand,
                          :team => u.name,
                          :country_phone_code => "+1")
        company.employees.build(:user_id => u.id,
                                :job_title => JOB_TITLE.rand,
                                :ondeego_email => "#{rand(100)}_#{Faker::Internet.email}",
                                :ondeego_phone => Faker.numerify("########"),
                                :status => Employee::Status::ACTIVE)
        company.save
      end
    end
    @companies_ids = Company.all.map(&:id)

    puts "Companies #{@companies_ids.size} created"
    puts "Employees creating..."
    @users.each do |u|
      ids = @companies_ids - u.companies.map(&:id)
      COMPANY_COUNT_PER_USER.times do
        Employee.create(:company_id => ids.rand,
                         :user_id => u.id,
                         :job_title => JOB_TITLE.rand,
                         :ondeego_email => "#{rand(100)}_#{Faker::Internet.email}",
                         :ondeego_phone => Faker.numerify("########"),
                         :status => STATUSES.rand)
      end
    end
    puts "Employees #{Employee.count} created"
    puts "Friends creating..."
    @users.each do |u|
      ids = @users_ids - [u.id]
      FRIENDS.times do
        status = STATUSES.rand
        friend_id = ids.rand
        f = Friendship.create(:user_id => u.id, :friend_id => friend_id, :friendship_id => 0, :status => status)
        Friendship.create(:user_id => friend_id, :friend_id => u.id, :status => status) unless f.blank?
      end
    end
    puts "Friends #{(Friendship.count / 2).to_i} created"
  end

  desc "Clear fake db data"
  task(:clear_fake_db) do
    require "#{Rails.root}/config/environment.rb"
    Friendship.destroy_all
    Employee.destroy_all
    Company.destroy_all
    User.destroy_all
  end
end
