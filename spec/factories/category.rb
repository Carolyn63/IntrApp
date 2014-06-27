Factory.define :category do |e|
  e.sequence(:name) { |n| "Category ##{ n }" }
end
