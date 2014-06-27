class CompanyApplication < ActiveRecord::Base

	belongs_to :payment
	belongs_to :service

	def self.create_company_application params
		@company_application = CompanyApplication.new(params)
		success = @company_application.save
		return success
	end

	def self.update_company_application params, user_id, attribute_id
		@company_application = CompanyApplication.find_by_user_id_and_attribute_id(user_id, attribute_id)
		success = @company_application.update_attributes(params) unless @company_application.blank?
		return success
	end

end
