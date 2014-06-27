Factory.define :company do |e|
  e.name                  { Faker::Company.name }
  e.address               { Faker::Address.name }
  e.city                  { Faker::Address.city }
  e.phone "55566183555"
  # company_type: "Parther"
  e.privacy               { Company::Privacy::PUBLIC }
  # industry: "IT"
  # size: "1"
  e.description "blabblabblabblab"
  e.team "Ben"
  # perishable_token: <%= Authlogic::Random.friendly_token %>

  e.association :admin, :factory => :user
end
