class PortalCloudstorageController < ApplicationController

	def add_company(company_id)
		ret = false
		company = Company.find_by_id(company_id)
		ent_username = company.name.gsub(/[\W]/i, "")
		ent_username = ent_username.slice(0,8)+company.id.to_s
		ent_username = ent_username.downcase
		ent_password = generate_password(8)
		encrypt_password = Tools::AESCrypt.new.encrypt(ent_password)
		uid = company_id
		if property(:use_digidata)
			cloud_sp = Cloudstorage.find_by_admin_type_and_name("serviceprovider", property(:serviceProvider))
			sp_username = cloud_sp.login
			sp_password  = Tools::AESCrypt.new.decrypt(cloud_sp.password)
			sp_level_collection = cloud_sp.name
			service = Services::DigidataApi::Api.new(sp_username, sp_password, sp_level_collection)
			logger.info "params for service #{sp_username}, #{sp_password}, #{sp_level_collection}"

			biz_level_collection = company.name
			biz_quota =  10 * 1024 * 1024 * 1024
			biz_admin = ent_username
			biz_pass = ent_password
			#biz_admin_email = company.user.service_email
			biz_admin_email = ent_username + '@' + property(:sogo_email_domain)
			response = service.create_biz_and_admin(biz_level_collection, biz_quota, biz_admin, biz_pass, biz_admin_email)
			logger.info "params for company #{biz_level_collection}, #{biz_quota}, #{biz_admin}, #{biz_pass}, #{biz_admin_email}"

			logger.info "response_code: #{response.code},#{response.body}"

			response_code = response.code
			if /^20/.match(response_code)
				logger.info "cloud storage creation successful for company #{company_id}, #{response.message}"

				# assign owner to the company
				response_assign_owner = service.assign_owner(biz_level_collection)
				response_code = response_assign_owner.code
				if /^20/.match(response_code)
					logger.info "cloud storage assign owner successful for company #{company_id}, #{response_assign_owner.message}"
				else
					logger.info "cloud storage assign owner failed for company #{company_id}, #{response_assign_owner.message}"
				end
			else
				logger.info "cloud storage creation failed for company #{company_id}, #{response.message}"
			end
		else
			response_code = "200"
		end
		if /^20/.match(response_code)
			c_quota =  10240 # 10 GB
			company_fields = {:uid => uid, :company_id => company_id, :admin_type => "enterprise", :name => company.name, :login => ent_username, :password =>encrypt_password, :quota => c_quota, :available_quota => c_quota, :date_created => Time.now}
			company_cloud = Cloudstorage.new(company_fields)
			if company_cloud.save
				logger.info "cloud storage successfully saved for company #{company_id}"
			end
			ret = true
		end
		return ret
	end

	def add_user user_id
		user = User.find_by_id(user_id)
		employee = user.employees[0]
		company = Company.find_by_id(employee.company_id)
		owner   = User.find_by_id(company.user_id)

		user_name = user.service_email
		uid = user.id
		if property(:use_digidata)
			user_login = user_name
			user_pass = Tools::AESCrypt.new.decrypt(user.user_password)
			user_quota = 1 * 1024 * 1024 * 1024
			user_email = user.email

			ent_cloud = Cloudstorage.find_by_admin_type_and_company_id("enterprise", company.id)
			biz_admin = ent_cloud.login
			biz_pass = Tools::AESCrypt.new.decrypt(ent_cloud.password)
			biz_level_collection = ent_cloud.name

			service = Services::DigidataApi::Api.new(biz_admin, biz_pass, biz_level_collection)
			logger.info "params for bz #{biz_level_collection}, #{biz_admin}, #{biz_pass}"

			response = service.create_user(biz_level_collection, user_login, user_pass, user_quota, user_email)
			response_code = response.code
			logger.info "response_code: #{response.code}"
			logger.info "params for user #{biz_level_collection}, #{user_login}, #{user_pass}, #{user_quota}, #{user_email}"

			if /^20/.match(response_code)
				logger.info "cloud storage creation successful for user #{user_id}, #{response.message}"
			else
				logger.info "cloud storage creation failed for user #{user_id}, #{response.message}"
				#flash[:error] = t("controllers.create.error.cloudstorage_user")
			end
		else
			response_code = "200"
		end
		
		u_quota = 1024
		logger.info "response_code: #{response_code}"

		if /^20/.match(response_code)
			fields = {:uid => uid, :company_id => employee.company_id,:employee_id => employee.id ,:admin_type => "user", :name => user.name, :login => user_name, :password =>user.user_password, :quota => u_quota, :date_created => Time.now}
			user_cloud = Cloudstorage.new(fields)
			if user_cloud.save 
				logger.info "cloud storage successfully saved for user #{user_id}"
				decrement_quota company.id, u_quota # decrease 1GB from company's available quota
				logger.info("ca quota decremented")
			end
		end
	end

	def remove_company company_id
		if property(:use_digidata)
			response_code = "200" # Api calls here
		else
			response_code = "200"
		end
		if /^20/.match(response_code)
			ent_cloud = Cloudstorage.find_by_company_id(company_id)
			unless ent_cloud.blank?
				ent_quota = ent_cloud.quota
				cloudstorages = Cloudstorage.find_all_by_company_id(company_id)
				cloudstorages.each do |cloud|
					cloud.destroy
				end
			end
		#Cloudstorage.delete_all "company_id ='" + company_id.to_s + "'"
		end
		increment_sp_quota ent_quota
	end

	def remove_user employee_id
		if property(:use_digidata)
			user_cloud = Cloudstorage.find_by_admin_type_and_employee_id("user", employee_id)
			if user_cloud.present?
			ent_cloud = Cloudstorage.find_by_admin_type_and_company_id("enterprise", user_cloud.company_id)
			biz_admin = ent_cloud.login
			biz_pass = Tools::AESCrypt.new.decrypt(ent_cloud.password)
			biz_level_collection = ent_cloud.name

			service = Services::DigidataApi::Api.new(biz_admin, biz_pass, biz_level_collection)

			response = service.delete_user(biz_level_collection, user_cloud.login)
			response_code = response.code
			logger.info "response_code: #{response.code}"
			end
	else
			response_code = "200"
		  end
		   if /^20/.match(response_code)
			unless user_cloud.blank?
				user_quota = user_cloud.quota
				company = Company.find_by_id(user_cloud.company_id)
				owner   = User.find_by_id(company.user_id)
				increment_quota company.id, user_quota
				user_cloud.destroy 
			end
		end
	end
  
	def remove_employees employee_ids
		employee_ids.each do |employee_id|
			 remove_user employee_id
		end
	end

	def add_user_disk_space employee_id, space
	end
  
	def add_company_disk_space company_id, quota
		if property(:use_digidata)
			response_code = "200" # Api calls here
		else
			response_code = "200"
		end
		if /^20/.match(response_code)
			ent_cloud = Cloudstorage.find_by_admin_type_and_company_id("enterprise", company_id)
			old_quota = ent_cloud.quota
			old_available_quota = ent_cloud.available_quota
			new_quota = old_quota.to_i + (quota.to_i* 1024)
			new_available_quota = old_available_quota.to_i + (quota.to_i* 1024)
			ent_cloud.update_attributes(:quota => new_quota, :available_quota => new_available_quota)
			#company = Company.find_by_id(company_id)
			#user = User.find_by_id(company.user_id)
			#user_cloud = Cloudstorage.find_by_employee_id_and_admin_type(user.employees[0].id, "user")
			#user_cloud.update_attributes(:quota => new_quota) 
		end
	end

	def decrement_quota company_id, quota
		if property(:use_digidata)
			response_code = "200" # Api calls here
		else
			response_code = "200"
		end
		
		if /^20/.match(response_code)
			ent_cloud = Cloudstorage.find_by_admin_type_and_company_id("enterprise", company_id)
			old_quota = ent_cloud.available_quota
			new_quota = old_quota.to_i - quota.to_i
			ent_cloud.update_attributes(:available_quota => new_quota)
		end
	end

	def increment_quota company_id, quota
		if property(:use_digidata)
			response_code = "200" # Api calls here
		else
			response_code = "200"
		end
		
		if /^20/.match(response_code)
			ent_cloud = Cloudstorage.find_by_admin_type_and_company_id("enterprise", company_id)
			old_quota = ent_cloud.available_quota
			new_quota = old_quota.to_i + quota.to_i
			ent_cloud.update_attributes(:available_quota => new_quota)
		end
	end

	def decrement_sp_quota quota
		if property(:use_digidata)
			response_code = "200" # Api calls here
		else
			response_code = "200"
		end
		
		if /^20/.match(response_code)
			sp_cloud = Cloudstorage.find_by_admin_type_and_name("serviceprovider", property(:serviceProvider))
			old_quota = sp_cloud.available_quota
			new_quota = old_quota.to_i - quota.to_i
			sp_cloud.update_attributes(:available_quota => new_quota)
		end
	end

	def increment_sp_quota quota
		if property(:use_digidata)
			response_code = "200" # Api calls here
		else
			response_code = "200"
		end
		
		if /^20/.match(response_code)
			sp_cloud = Cloudstorage.find_by_admin_type_and_name("serviceprovider", property(:serviceProvider))
			old_quota = sp_cloud.available_quota
			new_quota = old_quota.to_i + quota.to_i
			sp_cloud.update_attributes(:available_quota => new_quota)
		end
	end

=begin
	def decrement_quota company_id, employee_id, quota
		if property(:use_digidata)
			response_code = "200" # Api calls here
		else
			response_code = "200"
		end
		
		if response_code == "200"
			user_cloud = Cloudstorage.find_by_employee_id_and_admin_type(employee_id, "user")
			old_quota = user_cloud.quota
			new_quota = old_quota.to_i - (quota.to_i* 1024)
			user_cloud.update_attributes(:quota => new_quota)
		end
	end
  
  def increment_quota company_id, employee_id, quota
    if property(:use_digidata)
      response_code = "200" # Api calls here
    else
      response_code = "200"
    end
    
    if response_code == "200"
    user_cloud = Cloudstorage.find_by_employee_id_and_admin_type(employee_id, "user")
    old_quota = user_cloud.quota
    new_quota = old_quota.to_i + (quota.to_i* 1024)
    user_cloud.update_attributes(:quota => new_quota)
    end
  end
=end

end
# 1gb = 1024 mb