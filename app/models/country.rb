class Country < ActiveRecord::Base

  has_many :countrifications, :dependent => :destroy
  has_many :applications, :through => :countrifications

  validates_presence_of :country

  validates_presence_of :applications_count
  validates_numericality_of :applications_count

  named_scope :ordered, :order => :'country asc'

  def to_s; name; end
  
  def name
    "#{self.country}"
  end
end
