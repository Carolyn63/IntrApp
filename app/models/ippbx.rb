class Ippbx < ActiveRecord::Base

  belongs_to :company
  belongs_to :employee
  
  after_create :create_c2call_for_employees
  before_destroy :remove_c2call_for_employees 
  
  
  def self.create_ippbx params_fields
    unless params_fields.blank?
      @ippbx = Ippbx.new(params_fields)
      if @ippbx.save
      return true
      end
    end
  end

  def self.update_employee_ippbx params_fields,employee_id
    unless params_fields.blank?
    Ippbx.find_by_employee_id_and_admin_type(employee_id,"user").update_attributes(params_fields)
    return true
    end
  end

  def self.update_employee_password params_fields, uid
    unless params_fields.blank?
    Ippbx.find_by_uid_and_admin_type(uid, "user").update_attributes(params_fields)
    end
  end

  def self.destroy_employee_ippbx(employee_id)
    unless employee_id.blank?
    Ippbx.find_by_employee_id(employee_id).delete
    return true
    end
  end

  def self.destroy_employee_ippbx_by_ippbx_uid(ippbx_uid)
    unless ippbx_uid.blank?
    Ippbx.find_by_uid_and_admin_type(ippbx_uid,"user").delete
    return true
    end
  end

  def self.update_ippbx_user fields, uid
    
    ippbx = Ippbx.find_by_uid_and_admin_type(uid, "user")
    
    unless fields[:extension].blank?
      ippbx_params= {:name => fields[:firstname] + " " + fields[:lastname], :mobile_number => fields[:cellphone], :extension=>fields[:extension], :date_updated=>fields[:date_updated]}
    else
      ippbx_params= {:name => fields[:firstname] + " " + fields[:lastname], :mobile_number => fields[:cellphone], :date_updated=>fields[:date_updated]}
    end
    Ippbx.update(ippbx.id, ippbx_params)
    return true if User.update(ippbx.employee.user_id, fields)

  end

  #company
  def self.update_enterprise_ippbx params_fields, company_id
    unless params_fields.blank?
    Ippbx.find_by_company_id_and_admin_type(company_id, "enterprise").update_attributes(params_fields)
    return true
    end
  end

  def self.update_enterprise_password params_fields, uid
    unless params_fields.blank?
    Ippbx.find_by_uid_and_admin_type(uid, "enterprise").update_attributes(params_fields)
    end
  end

  def self.destroy_enterprise_ippbx(company_id)
    unless company_id.blank?
    Ippbx.find_by_company_id(company_id).delete
    return true
    end
  end

  def self.retrieve_public_number company_id
    @result_set = Ippbx.find_by_company_id_and_admin_type(company_id, "enterprise")
    return @result_set.public_number unless @result_set.blank?
  end

  def self.retrieve_vm_number company_id
    @result_set = Ippbx.find_by_company_id_and_admin_type(company_id, "enterprise")
    return @result_set.vm_number unless @result_set.blank?
  end
  
	def create_c2call_for_employees
=begin
	if self.admin_type == "user"
			employee = Employee.find_by_id(self.employee_id)
			#success = employee.create_c2call_service
			if property(:use_mobile_tribe) && employee.is_mobiletribe_connect == 1
				begin
					fields = {
						"portalUserId" => employee.company_email.to_s,
						"password" => employee.email_password,
						"crypted_password" => employee.email_password
		
						 }
						public_number = self.public_number
						fields["portalMetadata"] = htmlsafe(public_number)
			 logger.info("Fields.........#{fields}")	    
				Services::MobileTribe::Connector.new.create_c2call(employee.user.mobile_tribe_login, employee.user.mobile_tribe_password,fields)
				rescue Services::MobileTribe::Errors::MobileTribeError => e
					self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				end
			end
		end
=end
	end

	def remove_c2call_for_employees 
=begin 
		if self.admin_type == "user"
			employee = Employee.find_by_id(self.employee_id)
			if property(:use_mobile_tribe) && employee.is_mobiletribe_connect == 1
					begin
						fields = {
							"portalUserId" => employee.company_email.to_s,
							"password" => employee.email_password,
							"crypted_password" => employee.email_password
						}
											logger.info("Fields.........#{fields}")
											Services::MobileTribe::Connector.new.create_c2call(employee.user.mobile_tribe_login, employee.user.mobile_tribe_password,fields)
					rescue Services::MobileTribe::Errors::MobileTribeError => e
						self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
					end
			end
		end
=end
	end

	def htmlsafe(str)
		@escaped = URI::escape(str.to_s)
		return @escaped
	end

end
