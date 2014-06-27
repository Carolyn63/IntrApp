class LinkedinUser < ActiveRecord::Base

	@@per_page = 25

	named_scope :ordered, :order => :'lastname asc'

	named_scope :by_first_letter, lambda {|letter|
		letter.blank? ? {} : {:conditions => ["lower(lastname) LIKE ?", "#{letter}%"]}
	}

end