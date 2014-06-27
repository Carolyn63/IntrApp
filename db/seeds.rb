# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

require "factory_girl"

Factory.find_definitions

5.times { Factory(:device) }
5.times { Factory(:category) }

5.times { Factory(:application_type) }

10.times { Factory(:company) }
51.times { Factory(:application) }

