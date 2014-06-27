Factory.define :employee do |e|
  e.status      { Employee::Status::ACTIVE }
  e.job_title   { 'Manager' }
  e.sequence(:company_email) { |n| "user#{ n }@example.com" }
  e.association :user
  e.association :company
  e.association :department
end
