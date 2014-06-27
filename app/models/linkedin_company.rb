class LinkedinCompany < ActiveRecord::Base

	@@per_page = 25

	named_scope :ordered, :order => :'name asc'

	named_scope :by_first_letter, lambda {|letter|
		letter.blank? ? {} : {:conditions => ["lower(name) LIKE ?", "#{letter}%"]}
	}

end