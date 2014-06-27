class EmployeeDevice < ActiveRecord::Base

  belongs_to :device, :counter_cache => :employees_count
  belongs_to :employee

  validates_presence_of :device
  validates_presence_of :employee
  validates_uniqueness_of :employee_id, :scope => [:device_id]

end
