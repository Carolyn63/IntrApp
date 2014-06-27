require 'uri'
require 'net/http'
require 'net/https'
require 'date'

class Ipn::PaypalController < ApplicationController
	before_filter :require_no_user
	protect_from_forgery :except => [:create]

	def index

	end

	def create
		if request.post?

			@params = request.params

			@query_params = 'cmd=_notify-validate'
			@params.each_pair {|key, value| @query_params = @query_params + '&' + key + '=' + value if key != 'email' || key != 'items' }
			logger.info "IPN QUERY: #{@query_params}"
			#POST this data
			uri = URI.parse('https://www.sandbox.paypal.com')
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
			response = http.post('/cgi-bin/webscr' , @query_params)
			#http.finish

			if response

				logger.info "PAYPAL response code: #{response.code}"
				logger.info "PAYPAL response body: #{response.body}"

				if response.body.chomp == 'VERIFIED'

					logger.info "PAYPAL txn_type: #{@params[:txn_type]}"
					logger.info "PAYPAL subscr_id: #{@params[:subscr_id]}"

					if @params[:txn_type] == 'subscr_signup' || @params[:txn_type] == 'subscr_payment' || @params[:txn_type] == 'subscr_cancel'
						if Payment.find_by_transaction_type_and_subscription_id(@params[:txn_type],@params[:subscr_id])
							return
						end
					end

					user_email = @params[:email]
					@paypal_user = User.find_by_email(user_email.to_s)
					@company_id = Company.find_by_user_id(@paypal_user.id).id
					#ompany_id = @params[:company_id] unless @params[:company_id].blank?
					txn_type = @params[:txn_type]
					payment_status = @params[:payment_status]

					case txn_type
					when 'subscr_signup':
						if @params[:item_number].blank?
							item_number = @params[:items]
						else
							item_number = @params[:item_number]
						end
						payment_status = @params[:payment_status]
						payment_amount = @params[:mc_amount3]
						payment_currency = @params[:mc_currency]
						txn_id = @params[:txn_id]
						subscr_id = @params[:subscr_id]
						receiver_email = @params[:receiver_email]
						payer_email = @params[:payer_email]
						subscr_date = @params[:subscr_date]

						if !subscr_date.blank?
							subscr_date = DateTime.parse(subscr_date)
							logger.info "pased date: #{subscr_date}"
							transaction_date = subscr_date.strftime("%Y-%m-%d %H:%M:%S")
						else
							transaction_date = Time.new.strftime("%Y-%m-%d %H:%M:%S")
						end

						payment_params = {
							'user_id' => @paypal_user.id,
							'email' => user_email,
							'payer_email'=> payer_email,
							'payment_service' => 'paypal',
							'transaction_type' => txn_type,
							'transaction_id' => txn_id,
							'transaction_status' => 'Initiated',
							'amount' => payment_amount,
							'currency' => payment_currency,
							'transaction_date' => subscr_date.strftime("%Y-%m-%d %H:%M:%S"),
							'plan_ids' => item_number,
							'subscription_id' => subscr_id,
							'company_id' => @company_id
						}

						ServiceActivationController.new.create_monthly(payment_params, item_number, @paypal_user.id, @company_id, user_email)
					when 'subscr_payment':
						if @params[:item_number].blank?
							item_number = @params[:items]
						else
							item_number = @params[:item_number]
						end
						item_name = @params[:item_name]
						payment_status = @params[:payment_status]
						payment_amount = @params[:mc_gross]
						payment_date = @params[:payment_date]
						payment_currency = @params[:mc_currency]
						txn_id = @params[:txn_id]
						subscr_id = @params[:subscr_id]
						receiver_email = @params[:receiver_email]
						payer_email = @params[:payer_email]

						logger.info "payment_date: #{payment_date}"

						if !payment_date.blank?
							payment_date = DateTime.parse(payment_date)
							logger.info "pased date: #{payment_date}"
							transaction_date = payment_date.strftime("%Y-%m-%d %H:%M:%S")
							subscription_end = 1.month.since(payment_date).strftime("%Y-%m-%d %H:%M:%S")
							logger.info "subscription_end: #{subscription_end}"
						else
							transaction_date = Time.new.strftime("%Y-%m-%d %H:%M:%S")
						end

						payment_params = {
							'user_id' => @paypal_user.id,
							'email' => user_email,
							'payer_email'=> payer_email,
							'payment_service' => 'paypal',
							'transaction_type' => txn_type,
							'transaction_id' => txn_id,
							'transaction_status' => payment_status,
							'amount' => payment_amount,
							'currency' => payment_currency,
							'transaction_date' => payment_date.strftime("%Y-%m-%d %H:%M:%S"),
							'plan_ids' => item_number,
							'subscription_id' => subscr_id,
							'company_id' => @company_id
						}

						if(Payment.create_payment payment_params)
							payment = Payment.find_last_by_email(user_email)
							payment_id = payment.id
							logger.info "PAYPAL: #{user_email} payment created"

							if !item_number.blank?
								item_numbers = item_number.split(/\s*,\s*/)
								item_numbers.each do |item|
									plan_id = item
									plan = ApplicationPlan.find_by_id(plan_id)
									companification = Companification.find_by_plan_id_and_company_id(plan_id,@company_id)
									if !companification.blank?
										companification.status = "paid"
										companification.payment_id = payment_id
										plan.monthly? ? companification.end_at = subscription_end : ""
										if companification.save
											Order.find_by_id(companification.order_id).update_attributes(:status => "paid")
										end
									end
								 end
							end

							if !current_user.blank?
								if !check_company_services @paypal_user.email, @paypal_user.id
									check_services @paypal_user.email, @paypal_user.id # Set session true for the paid services
								end
							end
						else
							logger.info "PAYPAL: #{user_email} payment not created"
						end

					when 'subscr_cancel':
						subscr_id = @params[:subscr_id]
						payer_email = @params[:payer_email]
						subscr_date = @params[:subscr_date]
						item_number = params[:item_number]

						if !subscr_date.blank?
							subscr_date = DateTime.parse(subscr_date)
							transaction_date = subscr_date.strftime("%Y-%m-%d %H:%M:%S")
						else
							transaction_date = Time.new.strftime("%Y-%m-%d %H:%M:%S")
						end
						parent_subscription= Payment.find_by_subscription_id(subscr_id) #change
						payment_params = {
							'user_id' => @paypal_user.id,
							'email' => user_email,
							'payer_email'=> payer_email,
							'payment_service' => 'paypal',
							'transaction_type' => txn_type,
							'transaction_status' => 'Cancelled',
							'transaction_date' => subscr_date.strftime("%Y-%m-%d %H:%M:%S"),
							'subscription_id' => subscr_id,
							'payment_reason'=>'subscription cancelled on ' + subscr_date.strftime("%Y-%m-%d %H:%M:%S"),
							'parent_id' => parent_subscription.id,
							'company_id' => @company_id,
						        'plan_ids' => item_number
						}

						if(Payment.create_payment payment_params)
							payment = Payment.find_last_by_email(user_email)
							payment_id = payment.id
							logger.info "PAYPAL: #{user_email} cancellation created"
							Notifier.deliver_subscr_cancel(user_email,@paypal_user.login,@params[:item_name]) unless @params[:item_name].blank?

=begin							if !item_number.blank?
								item_numbers = item_number.split(/\s*,\s*/)
								item_numbers.each do |item|
									plan_id = item
									plan = ApplicationPlan.find_by_id(plan_id)
									companification = Companification.find_by_plan_id_and_company_id(plan_id,@company_id)
									if !companification.blank?
										companification.status = "cancelled"
										companification.payment_id = payment_id
										plan.monthly? ? companification.end_at = subscription_end : ""
										if companification.save
											Order.find_by_id(companification.order_id).update_attributes(:status => "cancelled")
										end
									end
								end
=end							end
						else
							logger.info "PAYPAL: #{user_email} cancel subscripton not created"
						end

					when 'recurring_payment_suspended_due_to_max_failed_payment':
						payment_params = {
							'email' => user_email,
							'payer_email'=> payer_email,
							'transaction_type' => txn_type,
							'transaction_id' => txn_id,
							'transaction_status' => 'Failed',
							'transaction_date' => payment_date.strftime("%Y-%m-%d %H:%M:%S"),
							'subscription_id' => recurring_payment_id,
							'payment_reason'=> 'recurring payment suspended due to max failed payment',
							'company_id' => @company_id
						}
						Payment.create_payment payment_params

					when "web_accept":
						if @params[:item_number].blank?
							item_number = @params[:items]
						else
							item_number = @params[:item_number]
						end
						payment_status = @params[:payment_status]
						payment_amount = @params[:mc_gross]
						payment_currency = @params[:mc_currency]
						txn_id = @params[:txn_id]
						receiver_email = @params[:receiver_email]
						payer_email = @params[:payer_email]
						payment_date = @params[:payment_date]
						payment_date = DateTime.parse(payment_date)
						if payment_status == "Completed"
							payment_params = {
							'user_id' => @paypal_user.id,
							'email' => user_email,
							'payer_email'=> payer_email,
							'payment_service' => 'paypal',
							'transaction_type' => "onetime_payment",
							'transaction_id' => txn_id,
							'transaction_status' => payment_status,
							'amount' => payment_amount,
							'currency' => payment_currency,
							'transaction_date' => payment_date.strftime("%Y-%m-%d %H:%M:%S"),
							'plan_ids' => item_number,
							'company_id' => @company_id
						}

						if(Payment.create_payment payment_params)
							logger.info "PAYPAL: #{user_email} payment created"

							if !item_number.blank?
								item_numbers = item_number.split(/\s*,\s*/)
								item_numbers.each do |item|
									plan_id = item
									plan = ApplicationPlan.find_by_id(plan_id)
									companification = Companification.find_by_plan_id_and_company_id(plan_id,@company_id)
									if !companification.blank?
										companification.status = "paid"
										companification.payment_id = payment_id
										plan.monthly? ? companification.end_at = subscription_end : ""
										if companification.save
											Order.find_by_id(companification.order_id).update_attributes(:status => "paid")
										        if plan.application_nature == "employee"
											                                basic_companification = Companification.find_by_plan_id_and_company_id(companification.application.basic_plan.id,@company_id)
															max_employees_count = basic_companification.max_employees_count + order.quantity
															basic_companification.update_attributes(:max_employees_count => max_employees_count)
															if companification.application.name.delete(' ').downcase.include?("ippbx")
															 PortalIppbxController.new.add_public_number(@company_id, order.quantity, order.id)
															end
											end
										
										end
									end
							
								end
							end
						else
							logger.info "PAYPAL: #{user_email} payment not created"
						end
						end

					end #end case

					if payment_status == "Refunded"
						#payment_status = @params[:payment_status]
						if @params[:item_number].blank?
							item_number = @params[:items]
						else
							item_number = ""
						end

						payment_date = @params[:payment_date]
						payment_currency = @params[:mc_currency]
						txn_id = @params[:txn_id]
						subscr_id = @params[:subscr_id]
						receiver_email = @params[:receiver_email]
						payer_email = @params[:payer_email]
						parent_subscription= Payment.find_by_subscription_id(subscr_id) #change
						if !payment_date.blank?
							payment_date = DateTime.parse(payment_date)
							logger.info "pased date: #{payment_date}"
							transaction_date = payment_date.strftime("%Y-%m-%d %H:%M:%S")
							subscription_end = 1.month.since(payment_date).strftime("%Y-%m-%d %H:%M:%S")
							logger.info "subscription_end: #{subscription_end}"
						else
							transaction_date = Time.new.strftime("%Y-%m-%d %H:%M:%S")
						end
						payment_params = {
							'user_id' => @paypal_user.id,
							'email' => user_email,
							'payer_email'=> payer_email,
							'payment_service' => 'paypal',
							'transaction_type' => 'subscr_refund',
							'transaction_status' => 'Refunded',
							'transaction_date' => payment_date.strftime("%Y-%m-%d %H:%M:%S"),
							'subscription_id' => subscr_id,
							'plan_ids' => item_number,
							'payment_reason'=>'subscription Refunded on ' + payment_date.strftime("%Y-%m-%d %H:%M:%S"),
							'parent_id' => parent_subscription.id
						}
						if(Payment.create_payment payment_params)
							logger.info "PAYPAL: #{user_email} Refund subscription created"
							if property(:paid_true_after_refund)
								paid = "paid"
								status = "paid"
							else
								paid = "rejected"
								status = "cancelled"
							end
							
							if !item_number.blank?
								item_numbers = item_number.split(/\s*,\s*/)
								item_numbers.each do |item|
									plan_id = item
									plan = ApplicationPlan.find_by_id(plan_id)
									companification = Companification.find_by_plan_id_and_company_id(plan_id,@company_id)
									if !companification.blank?
										companification.status = status
										companification.payment_id = payment_id
										plan.monthly? ? companification.end_at = subscription_end : ""
										if companification.save
											Order.find_by_id(companification.order_id).update_attributes(:status => status)
										end
									end
								end
							end
						else
							logger.info "PAYPAL: #{user_email} Refund subscripton not created"
						end
					end #if payment_status == "Refunded"

				end #if response.body.chomp == 'VERIFIED'
			end #if response
		end #if request.post?

		#rescue Exception => e
			#logger.info("Error: paypal transaction #{e.message}")
		#end
	end

end