Factory.define :device do |e|
  e.sequence(:name) { |n| "Device ##{ n }" }
  e.description { Faker::Lorem.sentences(3).join("\n") }
end
