class Typization < ActiveRecord::Base
  belongs_to :application
  belongs_to :application_type, :counter_cache => :applications_count

  validates_presence_of :application
  validates_presence_of :application_type
  validates_uniqueness_of :application_type_id, :scope => :application_id
end
