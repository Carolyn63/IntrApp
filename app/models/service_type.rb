class ServiceType < ActiveRecord::Base
   has_many  :services
   has_many :payments ,:through => :services 
   
   validates_presence_of :name, :service_code, :subscription_fee, :currency
   
end
