class Cloudstorage < ActiveRecord::Base

	belongs_to :company
	belongs_to :employee
	after_create :send_welcome_email
	#before_destroy :send_delete_email


	def send_welcome_email
		if property(:use_digidata)==true
			if self.admin_type == "enterprise"
				company = Company.find_by_id(self.company_id)
				user = User.find_by_id(company.user_id)
				personal_email = user.email
				service_email  = user.service_email
				password = Tools::AESCrypt.new.decrypt(self.password)
				CloudstorageNotifier.deliver_welcome_ent_admin(company.name+" Admin", self.login, password, personal_email)
				CloudstorageNotifier.deliver_welcome_ent_admin(company.name+" Admin", self.login, password, service_email)
			else
				employee = Employee.find_by_id(self.employee_id)
				user = employee.user
				personal_email = user.email
				service_email  = user.service_email
				password = Tools::AESCrypt.new.decrypt(self.password)
				CloudstorageNotifier.deliver_welcome_user_admin(user.name, self.login, password, personal_email)
				CloudstorageNotifier.deliver_welcome_user_admin(user.name, self.login, password, service_email)
			end
		end
	end

	def send_delete_email
		if property(:use_digidata)==true
			logger.info("11111111111.. cloud delete")
			if self.admin_type == "enterprise"
				logger.info("2222222222222.. cloud delete ent")
				company = Company.find_by_id(self.company_id)
				user = User.find_by_id(company.user_id)
				personal_email = user.email
				service_email  = user.service_email
				CloudstorageNotifier.deliver_ent_admin_delete(user.login, personal_email)
				CloudstorageNotifier.deliver_ent_admin_delete(user.login, service_email)
			else
				logger.info("2222222222222.. cloud delete user")
				employee = Employee.find_by_id(self.employee_id)
				user = employee.user
				personal_email = user.email
				service_email  = user.service_email
				CloudstorageNotifier.deliver_user_admin_delete(user.login, personal_email)
				CloudstorageNotifier.deliver_user_admin_delete(user.login, service_email)
				logger.info("33333333333.. cloud delete user")
			end
		end
	end

	end