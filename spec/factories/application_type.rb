Factory.define :application_type do |e|
  e.sequence(:name) { |n| "ApplicationType ##{ n }" }
  e.description { Faker::Lorem.sentences(3).join("\n") }
end
