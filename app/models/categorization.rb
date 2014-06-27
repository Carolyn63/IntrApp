class Categorization < ActiveRecord::Base

  belongs_to :application
  belongs_to :category, :counter_cache => :applications_count

  validates_presence_of :application
  validates_presence_of :category

end
