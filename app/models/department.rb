class Department < ActiveRecord::Base
	belongs_to :company
	has_many :department_applications, :dependent => :destroy
        has_many :applications, :through => :department_applications
	has_many :employees, :dependent => :nullify
        validates_length_of :name, :in => 1..128
	after_create :create_department_with_service, :if => :multi_tenant
	#before_update :prepare_need_update_flags
	before_update :update_department_with_service, :if => :multi_tenant
	before_destroy :delete_department_with_service, :if => :multi_tenant
	#after_validation :prepare_need_update_flags

	#attr_accessor :need_mobile_tribe_attr_update
         named_scope :by_application_id, lambda { |application_id|
          application_id.blank? ? {} : { :conditions => ["department_applications.application_id = ?", application_id], :joins => [:department_applications] }
         } 
	def multi_tenant
		if property(:is_multi_tenant)
			return true
		else
			return false
		end
	end
=begin
	def prepare_need_update_flags
	        self.need_mobile_tribe_attr_update = false
		u = Department.find_by_id(self.id)
		unless u.blank?
			self.need_mobile_tribe_attr_update = %w{name}.any? do |f|
				u.send(f.to_sym) != self.send(f.to_sym)
			end
		end
	end
=end
	def mobiletribe_connect!
	  self.update_attribute("is_mobiletribe_connect", 1)
	end


	def mobiletribe_connect?
	  self.is_mobiletribe_connect == 1
	end

	private 

	def create_department_with_service
		if(property(:use_mobile_tribe))
			begin
				mobile_tribe = Services::MobileTribe::Connector.new
				mobile_tribe.create_department("departmentId" => "-"+self.id.to_s,
					"companyId" => self.company_id,
					"departmentName" => htmlsafe(self.name))
				#self.update_attribute("is_mobiletribe_connect","1")
				self.mobiletribe_connect!
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				self.delete
				self.send(rollback_changes("mt_error"))
				return false
			end
		end
	end

	def update_department_with_service
	        need_mt_update = false
		u = Department.find_by_id(self.id)
		unless u.blank?
			need_mt_update = %w{name}.any? do |f|
				u.send(f.to_sym) != self.send(f.to_sym)
			end
		end
	 	if(property(:use_mobile_tribe)) && self.mobiletribe_connect?
		  	begin
				comp = Company.find_by_id(self.company_id)
				user = User.find_by_id(comp.user_id)
				mobile_tribe = Services::MobileTribe::Connector.new
				mobile_tribe.update_department(
					"companyId" => self.company_id,
					"departmentId" => "-"+self.id.to_s,
					"userId" => user.id,
					"departmentName" => htmlsafe(self.name),
					"description" => htmlsafe(self.description)
				) if need_mt_update
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base("#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				self.send(rollback_changes("mt_error"))
			end
		end
	end

	def delete_department_with_service 
		if(property(:use_mobile_tribe)) && self.mobiletribe_connect?
		 begin
			 update_employees
			 mobile_tribe = Services::MobileTribe::Connector.new
			 mobile_tribe.destroy_department(
				"departmentId" => "-"+self.id.to_s,
				"companyId" => self.company_id
			)
		 rescue Services::MobileTribe::Errors::MobileTribeError => e
			 self.errors.add_to_base("#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}")
			 self.send(rollback_changes("mt_error")) 
			end
		end
	end

	def update_employees
		if(property(:use_mobile_tribe))
		 begin
		         mobile_tribe = Services::MobileTribe::Connector.new
			 employees = Employee.find_all_by_department_id(self.id)
			 employees.each do |employee|
			        if employee.is_mobiletribe_connect == 1
				  puts "#{employee.inspect}"
				  mobile_tribe.update_employee("employeeId" => employee.id.to_s, "companyId" =>  employee.company_id.to_s, "departmentId" => "")
				end
			 end
		 rescue Services::MobileTribe::Errors::MobileTribeError => e
			self.errors.add_to_base("#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}")
			self.send(rollback_changes("mt_error"))
		 end
		end
	end

	def rollback_changes(message)
		raise ActiveRecord::Rollback, message 
		return false 
	end

	def htmlsafe(str)
		@escaped = URI::escape(str.to_s)
		return @escaped
	end

end