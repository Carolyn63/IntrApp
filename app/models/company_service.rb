class CompanyService < ActiveRecord::Base

	belongs_to :payment
	belongs_to :service

	def self.create_company_service params
		@company_service = CompanyService.new(params)
		success = @company_service.save
		return success
	end

	def self.update_company_service params, user_id, service_id
		@company_service = CompanyService.find_by_user_id_and_service_id(user_id, service_id)
		success = @company_service.update_attributes(params) unless @company_service.blank?
		return success
	end

end
