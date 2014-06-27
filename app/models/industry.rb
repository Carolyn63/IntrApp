class Industry < ActiveRecord::Base

  has_many :industrialization, :dependent => :destroy
  has_many :applications, :through => :industrialization

  validates_presence_of :industry

  validates_presence_of :applications_count
  validates_numericality_of :applications_count

  named_scope :ordered, :order => :'industry asc'

  def to_s; industry; end

   def name
    "#{self.industry}"
  end

end
