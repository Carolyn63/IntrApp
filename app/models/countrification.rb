class Countrification < ActiveRecord::Base

  belongs_to :application
  belongs_to :country, :counter_cache => :applications_count

  validates_presence_of :application
  validates_presence_of :country

end
