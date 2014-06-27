class ServiceActivationController < ApplicationController

	def create_monthly payment_params, item_number,user_id, company_id, user_email
		if(Payment.create_payment payment_params)
			logger.info "PAYPAL: #{user_email} subscription created"
			payment = Payment.find_last_by_email(user_email)
			payment_id = payment.id
			logger.info("item number...#{item_number}")
			if !item_number.blank?
				logger.info("11111111111111111111111")
				item_numbers = item_number.split(",")
				item_numbers.each do |item|
					plan_id = item
					plan = ApplicationPlan.find_by_id(plan_id)
					companification = Companification.find_by_plan_id_and_company_id_and_status(plan_id,company_id,"pending")
					if !companification.blank?
						companification.status = "trial"
						companification.payment_id = payment_id
						#plan.monthly? ? companification.end_at = ""
						if companification.save
							logger.info "PAYPAL: #{user_email} companification created"
							order = Order.find_by_id(companification.order_id)
							order.update_attributes(:status => "trial")
							if plan.code.delete(' ').downcase.include?("ippbx") and plan.application_nature == "basic"
							#if  PortalIppbxController.new.add_company_ippbx(@company_id)
								PortalIppbxController.new.add_company_ippbx(company_id, companification.max_employees_count)
								if companification.max_employees_count > 0
									count = true
								else
									count = false
								end
								PortalIppbxController.new.add_user_ippbx(user_id,count)

							#Companification.decrement_counter(:max_employees_count, companification.id)
							#end
							elsif plan.code.delete(' ').downcase.include?("cloud") and plan.application_nature == "basic"
								if PortalCloudstorageController.new.add_company(company_id)
									PortalCloudstorageController.new.add_user(user_id)
								end
							end
							if plan.application_nature == "employee"
								basic_companification = Companification.find_by_plan_id_and_company_id(companification.application.basic_plan.id,company_id)
								max_employees_count = basic_companification.max_employees_count + order.quantity
								basic_companification.update_attributes(:max_employees_count => max_employees_count)
								if companification.application.name.delete(' ').downcase.include?("ippbx")
									PortalIppbxController.new.add_public_number(company_id, order.quantity, order.id)
								end
							elsif plan.application_nature == "addon"
								if companification.application.name.delete(' ').downcase.include?("cloud")
									PortalCloudstorageController.new.add_company_disk_space(company_id, order.quantity)
								end
							end
						end #comp save
					end #comp blank
				end #itm each
			end #item blank
		else
			logger.info "PAYPAL: #{user_email} subscription not created"
		end
	end

end