class Device < ActiveRecord::Base
  has_many :employee_devices, :dependent => :destroy
  has_many :employees, :through => :employee_devices

  has_many :devicefications, :dependent => :destroy
  has_many :applications, :through => :devicefications

  validates_presence_of :name
  validates_presence_of :applications_count
  validates_presence_of :employees_count

  named_scope :ordered, :order => :'name asc'

  named_scope :by_ids, lambda {|device_ids| 
  device_ids.blank? ? {} : {:conditions => ["id IN(?)", device_ids]}}

  def to_s; name; end
  
  
end
