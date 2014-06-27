class Service < ActiveRecord::Base
	has_many  :company_services
	has_many :payments ,:through => :company_services 

	validates_presence_of :name, :service_code, :amount, :currency
end