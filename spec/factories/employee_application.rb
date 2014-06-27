Factory.define :employee_application do |e|
  e.association :application
  e.association :employee
end
