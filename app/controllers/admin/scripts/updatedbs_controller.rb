class Admin::Scripts::UpdatedbsController < Admin::ResourcesController

	def index
	end

	def updateuser
		mobile_tribe = Services::MobileTribe::Connector.new
		users = User.find(:all)
		users.each do |user|
		if user.is_mobiletribe_connect == 0
			begin
				password = Tools::AESCrypt.new.decrypt(user.user_password)
				mobile_tribe.create_user(
					"userId" => user.id,
					"username" => user.mobile_tribe_login,
					"password" => password,
					"firstName" => htmlsafe(user.firstname),
					"lastName" => htmlsafe(user.lastname),
					"email" => htmlsafe(user.email.to_s)
				) 
				user.update_attribute("is_mobiletribe_connect", "1")
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				user.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
			end
			end
		end
		flash[:notice] = "Update uers successfully"
		redirect_to :action => :index
	end

	def updatecompany
		mobile_tribe = Services::MobileTribe::Connector.new
		companies = Company.find(:all)
		companies.each do |company|
		if company.is_mobiletribe_connect == 0 
			empId = Employee.find_by_company_id(company.id)
			begin
				fields = {
					"companyId" => htmlsafe(company.id),
					"companyName" => htmlsafe(company.name.to_s),
					"userId" => htmlsafe(company.user_id),
					"employeeId" => htmlsafe(empId.id.to_s),
					"description" => htmlsafe(company.description.to_s),
					"companyPhone" => htmlsafe(company.phone.to_s),
					"companyPhoneCountryCode" => htmlsafe(company.country_phone_code.to_s),
					"address" => htmlsafe(company.address.to_s),
					"city" => htmlsafe(company.city.to_s),
					"country" => htmlsafe(company.country.to_s),
					"state" => htmlsafe(company.state.to_s),
					"companyWebsite" => htmlsafe(company.website.to_s),
					"companyFacebook" => htmlsafe(company.facebook.to_s),
					"companyTwitter" => htmlsafe(company.twitter.to_s),
					"companyIndustry" => htmlsafe(company.industry.to_s),
					"companyTeamLeaders" => htmlsafe(company.team.to_s),
					"country" =>  htmlsafe(company.country.to_s),
					"state" => htmlsafe(company.state.to_s)
				}

				mobile_tribe.create_company(fields)
				company.update_attribute("is_mobiletribe_connect", "1")
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				company.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
			end
			end
		end
		flash[:notice] = "Update companies successfully"
		redirect_to :action => :index
	end

	def updatedepartment
		mobile_tribe = Services::MobileTribe::Connector.new
		departments = Department.find(:all)
		departments.each do |department|
			if department.is_mobiletribe_connect == 0
				begin
					mobile_tribe.create_department(
						"departmentId" => "-"+department.id.to_s,
						"companyId" => department.company_id,
						"departmentName" => htmlsafe(department.name)
					)
					department.update_attribute("is_mobiletribe_connect","1")  
				rescue Services::MobileTribe::Errors::MobileTribeError => e
					department.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				end
			end
		end
		flash[:notice] = "Update departments successfully"
		redirect_to :action => :index
	end

	def updateemployee
		mobile_tribe = Services::MobileTribe::Connector.new
		employees = Employee.find(:all)
		employees.each do |employee|
			if employee.status == 'active' && employee.is_mobiletribe_connect == 0 
				begin
					user = User.find_by_id(employee.user_id)
					ippbx_enabled = "0" 
					public_number = ""
					ippbx = Ippbx.find_by_admin_type_and_employee_id("user", employee.id)
					if !ippbx.blank?
					  ippbx_enabled = "1" 
					  public_number = ippbx.public_number
					end
					fields = {
						"companyId" => htmlsafe(employee.company_id.to_s),
						"userId" => htmlsafe(employee.user_id.to_s),
						"employeeId" => htmlsafe(employee.id.to_s),
						"firstName" => htmlsafe(user.firstname.to_s),
						"lastName" => htmlsafe(user.lastname.to_s),
						"status" => htmlsafe(employee.status.to_s),
						#"phone" => htmlsafe(user.phone.to_s),
						"companyEmail" => htmlsafe(employee.company_email.to_s),
						"officePhone" => htmlsafe(user.phone.to_s),
						"jobTitle" => htmlsafe(employee.job_title.to_s)
					}
					if employee.department_id.blank?
						fields["departmentId"] = ""
					else
						fields["departmentId"] = htmlsafe("-"+employee.department_id.to_s)
					end

					mobile_tribe.create_employee(fields)
					employee.update_attribute("is_mobiletribe_connect", "1")

				rescue Services::MobileTribe::Errors::MobileTribeError => e
					user.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				end
			end
		end
		flash[:notice] = "Update employees successfully"
		redirect_to :action => :index
	end

	def updatefriendship
		mobile_tribe = Services::MobileTribe::Connector.new 
		friendships = Friendship.find(:all)
		friendships.each do |friendship|
			if friendship.is_mobiletribe_connect == 0
				if friendship.friendship_id == 0
					begin
						fields = {"userId" => htmlsafe(friendship.user_id.to_s), "friendId" => htmlsafe(friendship.friend_id.to_s)}
						mobile_tribe.create_friendship(fields)
						friendship.update_attribute("is_mobiletribe_connect", "1")
					rescue Services::MobileTribe::Errors::MobileTribeError => e				
						friendship.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
					end
				else
					begin
						if (friendship.status == "active")
							friendship_status = 'accept' 
						elsif(friendship.status == "rejected")
							friendship_status = 'rejected'
						else
							next
						end
						fields = {"userId" => friendship.user_id, "friendId" => friendship.friend_id, "friendAction" => friendship_status}
						mobile_tribe.update_friendship(fields)
						friendship.update_attribute("is_mobiletribe_connect", "1")
					rescue Services::MobileTribe::Errors::MobileTribeError => e
						friendship.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
					end
				end
			end
		end
		flash[:notice] = "Update friendship successfully"
		redirect_to :action => :index
	end

	def updatesogo
		if property(:use_sogo)
			logger.info("Updating Sogo.............")
			employees = Employee.find(:all)
			employees.each do |employee|
				if employee.status == 'active' && employee.is_sogo_connect == 0
				#if employee.status == 'active'
					sogo = Services::Sogo::Wrapper.new
					begin
						logger.debug("Sogo for Id................ #{employee.id}")
						sogo.create_user(:email => employee.company_email,
						:password => employee.email_password,
						:crypted_password => Tools::MysqlEncrypt.mysql_encrypt(employee.email_password),
						:full_name => employee.user.name)

						employee.update_attribute("is_sogo_connect", "1")
						logger.info("Database Updated for Id................#{employee.id}")
					rescue Services::Sogo::Errors::OnWrapperError => e
						logger.debug("Exception.........#{e.to_s}")
						employee.errors.add_to_base("#{I18n.t('models.company.sogo_error')} #{e.to_s}")
					end
				end  
			end
			flash[:notice] = "Update Sogo successfully"
			redirect_to :action => :index
		end
	end

	def updatec2call
#=begin
		mobile_tribe = Services::MobileTribe::Connector.new

		employees = Employee.find(:all)
		error = ""
		employees.each do |employee|
			fields = {
				"portalUserId" => employee.company_email.to_s,
				"password" => employee.email_password,
				"crypted_password" => employee.email_password,
			}

			if employee.status == 'active' && employee.is_mobiletribe_connect == 1 
				begin
					mobile_tribe.create_c2call(employee.user.mobile_tribe_login, employee.user.mobile_tribe_password,fields)
					logger.debug "c2call registration #{employee.user.login}, #{employee.company_email.to_s}"

				rescue Services::MobileTribe::Errors::MobileTribeError => e
					error = error + "#{employee.id}"
					employee.errors.add_to_base("register c2call: #{e.to_s}")
				end
			end
		end
#=end
=begin
		mobile_tribe = Services::MobileTribe::Connector.new

		employee = Employee.find_by_id(512)
		error = ""
		fields = {
			"portalUserId" => employee.company_email.to_s,
			"password" => employee.email_password,
			"crypted_password" => employee.email_password,
		}

		logger.debug "c2call registration #{fields.to_json}"

		if employee.status == 'active' && employee.is_mobiletribe_connect == 1
			begin
				logger.debug "c2call registration #{employee.id}"
				mobile_tribe.create_c2call(employee.user.mobile_tribe_login, employee.user.mobile_tribe_password,fields)
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				error = error + "#{employee.id}"
				employee.errors.add_to_base("register c2call: #{e.to_s}")
			end
		end
=end


		if error == ""
			flash[:notice] = "Update C2Call successfully"
		else
			flash[:notice] = "Failed to update C2Call " + error
		end
		redirect_to :action => :index
	end

	def htmlsafe(str)
		@escaped = URI::escape(str.to_s)
		return @escaped
	end

	def change_friendship_status friendship
		begin
			mobile_tribe = Services::MobileTribe::Connector.new 
			if (friendship.status == "active")
				friendship_status = 'accept'
				fields = {
					"userId" => user_id,
					"friendId" => friend_id,
					"friendAction" => friendship_status
				}
			elsif(self.status == "rejected")
				friendship_status = 'rejected'
				fields = {
					"userId" => user_id,
					"friendId" => friend_id,
					"friendAction" => friendship_status
				}
			end
			mobile_tribe.update_friendship(fields)   
		rescue
			friendship.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
		end
	end

end
