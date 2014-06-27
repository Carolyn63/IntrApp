class Category < ActiveRecord::Base

  has_many :categorizations, :dependent => :destroy
  has_many :applications, :through => :categorizations

  validates_presence_of :name

  validates_presence_of :applications_count
  validates_numericality_of :applications_count

  named_scope :ordered, :order => :'name asc'

  def to_s; name; end

end
