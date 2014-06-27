Factory.define :employee_device do |e|
  e.association :device
  e.association :employee
end
