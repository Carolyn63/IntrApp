Factory.define :application do |e|
  e.sequence(:name) { |n| "Application ##{ n }" }
  e.status          { 0 }
  e.external_url    { "http://example.com" }
  e.description     { Faker::Lorem.sentences(3).join("\n") }
  e.devices         { [Factory.create(:device)] }
end
