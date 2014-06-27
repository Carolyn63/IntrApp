class Industrialization < ActiveRecord::Base

  belongs_to :application
  belongs_to :industry, :counter_cache => :applications_count

  validates_presence_of :application
  validates_presence_of :industry

end
