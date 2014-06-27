class ApplicationType < ActiveRecord::Base

  has_many :typizations, :dependent => :destroy
  has_many :applications, :through => :typizations

  validates_presence_of :name

  named_scope :ordered, :order => :'name asc'

  def to_s; name; end
end
