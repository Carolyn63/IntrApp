Factory.define :department do |e|
  e.sequence(:name) { |n| "Department ##{ n }" }
  e.association :company
end
