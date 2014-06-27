require 'uri'
require 'net/http'
require 'net/https'
require 'date'
require 'SignatureUtilsForOutbound'

class Ipn::AmazonController < ApplicationController
	before_filter :require_no_user
	protect_from_forgery :except => [:create]

  #before_filter :require_https, :only => [:create]
  #before_filter :require_http, :except => [:create] 
  def index
    
  end


	def create
#=begin
		#begin
			if request.post?
				utils = SignatureUtilsForOutbound.new();

				params = request.params

				user_email = params[:email]

				params.delete("email")
				params.delete("action")
				params.delete("controller")
				if !params[:company_id].blank?
				company_id = params[:company_id]
				params.delete("company_id")
				end
				#logger.info("params after delete #{params.to_s}")

				url_end_point = property(:app_site) + "/ipn/amazon"
				#response = utils.validate_request(:parameters => params, :url_end_point => url_end_point, :http_method => "POST")

				#logger.info "AMAZON response body: #{response.to_s}"

				response = true

				if response && response == true

					@params = request.params

					txn_type = ""
					if params[:status] == "PS" && params[:operation] == "pay" && params[:transactionId]
						txn_type = "subscr_payment"
					elsif params[:status] == "SubscriptionSuccessful"
						txn_type = "subscr_signup"
					elsif params[:status] == "SubscriptionCanceled"
						txn_type = "subscr_cancel"
					end

					if @params[:subscriptionId] && txn_type!=""
						if Payment.find_by_transaction_type_and_subscription_id(txn_type,@params[:subscriptionId])
							return
						end

						logger.info "AMAZON txn_type: #{txn_type}"
						logger.info "AMAZON subscr_id: #{@params[:subscriptionId]}"
					end

					amount = @params[:transactionAmount].split(" ")
					payment_reason = @params[:paymentReason]
					subscription_id = @params[:subscriptionId]
					item_number = @params[:referenceId]
					payment_status = @params[:status]
					payment_amount = amount[1]
					payment_date = @params[:transactionDate]
					payment_currency = amount[0]
					txn_id = @params[:transactionId]
					subscr_id = @params[:subscriptionId]
					payer_email = @params[:buyerEmail]

					if !payment_date.blank?
						payment_date = DateTime.strptime(payment_date,'%s')
						subscription_end = 1.month.since(payment_date).strftime("%Y-%m-%d %H:%M:%S")
						logger.info "subscription_end: #{subscription_end}"
						transaction_date = payment_date.strftime("%Y-%m-%d %H:%M:%S")
					else
						transaction_date = Time.new.strftime("%Y-%m-%d %H:%M:%S")
						subscription_end = 1.month.since(Time.new).strftime("%Y-%m-%d %H:%M:%S")
					end

					logger.info "transaction_date: #{payment_date}"

					@amazon_user = User.find_by_email(user_email.to_s)
					@company_id = Company.find_by_user_id(@amazon_user.id).id

					case params[:status]
					when 'PI' #Payment has been initiated
					when 'PS' #The payment transaction was successful.
						then
							if params[:operation] == "pay"
								txn_type = "subscr_payment"

								payment_params = {
									'user_id' => @amazon_user.id,
									'company_id' => @company_id,
									'email' => user_email,
									'payer_email'=> payer_email,
									'payment_service' => 'amazon',
									'transaction_type' => txn_type,
									'transaction_id' => txn_id,
									'transaction_status' => "Completed",
									'amount' => payment_amount,
									'currency' => payment_currency,
									'transaction_date' => transaction_date,
									'plan_ids' => item_number,
									'subscription_id' => subscr_id,
									'payment_reason' =>  payment_reason,
									'company_id' => @company_id
								}

								if  subscr_id.blank?
									payment_params['subscription_id'] = ""
									payment_params['transaction_type'] = "onetime_payment"
								end

								if(Payment.create_payment payment_params)
									payment = Payment.find_last_by_email(user_email)
									payment_id = payment.id
									logger.info "AMAZON: #{user_email} payment created"
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
								else
									logger.info "AMAZON: #{user_email} payment not created"
								end
							elsif params[:operation] == "refund"
								payment_params[:transaction_status] = "REFUND"
								if(Payment.create_payment payment_params)
									logger.info "AMAZON: #{user_email} payment created"
								else
									logger.info "AMAZON: #{user_email} payment not created"
								end
							elsif params[:operation] == "failure" and !subscr_id.blank?
								payment_params[:transaction_status] = "FAILURE" 
								if(Payment.create_payment payment_params)
								  payment = Payment.find_last_by_email(user_email)
									payment_id = payment.id
									item_numbers = item_number.split(/\s*,\s*/)
									item_numbers.each do |item|
										plan_id = item
										plan = ApplicationPlan.find_by_id(plan_id)
										companification = Companification.find_by_plan_id_and_company_id(plan_id,@company_id)
										if !companification.blank?
											companification.status = "rejected"
											plan.monthly? ? companification.end_at = subscription_end : ""
											Order.active_or_pending(@amazon_user, plan_id).update_attributes(:status => "cancelled")
										end
									end

									logger.info "AMAZON: #{user_email} payment created"

								else
									logger.info "AMAZON: #{user_email} payment not created"
								end
							elsif params[:operation] == "temporary_decline"
								payment_params[:transaction_status] = "TEMPORARY_DECLINE"
								if(Payment.create_payment payment_params)
									logger.info "AMAZON: #{user_email} payment created"
								else
									logger.info "AMAZON: #{user_email} payment not created"
								end
								email = "junewhee@gmail.com"
								Notifier.send_payment_notification(email, txn_id, user_email)
							end
					when 'PF' #The payment transaction failed
					when 'PR' #The reserve transaction was successful.
					when 'RS' #The refund transaction was successful.
					when 'RF' #The refund transaction failed.
					when 'SubscriptionSuccessful'
						txn_type = "subscr_signup"

								payment_params = {
									'user_id' => @amazon_user.id,
									'email' => user_email,
									'payer_email'=> payer_email,
									'payment_service' => 'amazon',
									'transaction_type' => txn_type,
									'transaction_id' => txn_id,
									'transaction_status' => "Initiated",
									'amount' => payment_amount,
									'currency' => payment_currency,
									'transaction_date' => transaction_date,
									'plan_ids' => item_number,
									'subscription_id' => subscr_id,
								 	'payment_reason' =>  payment_reason,
									'company_id' => @company_id
								}

								ServiceActivationController.new.create_monthly(payment_params, item_number, @amazon_user.id, @company_id, user_email)
					when 'SubscriptionCompleted'
					when 'SubscriptionCanceled'
						# need to create (or update) for cancellation
						then
							payment = Payment.find_last_by_email(user_email)
							if !payment.blank?
								field ={"transactionStatus" => "Cancelled", "paymentReason"=> "subscription cancelled on " + transaction_date}
								payment.update_attributes(field)
							end
					end
				end
			end
		#rescue Exception => e
			#logger.info("Error: Amazon transaction #{e.message}")
		#end
#=end
	end

	def create_payment
	end

end


#PS The payment transaction was successful.
#PF The payment transaction failed and the money was not transferred. You can redirect your customer to the Amazon Payments Payment Authorization page to select a different payment method.
#PI Payment has been initiated. It will take between five seconds and 48 hours to complete, based on the availability of external payment networks and the riskiness of the transaction.
#PR The reserve transaction was successful.
#RS The refund transaction was successful.
#RF The refund transaction failed.
#PaymentSuccess Amazon collected a subscription payment.
#PendingUserAction Amazon tried to collect a payment which failed due to a payment method error. The subscriber has been advised to adjust the method. Amazon will retry the payment after 6 days.
#PaymentRescheduled Amazon tried to collect a payment which failed due to an error not involving a payment method. Amazon will retry the payment after 6 days.
#PaymentCancelled Amazon has failed to collect a payment, and will not make any more attempts. Other subscription payments will be attempted on schedule.
#SubscriptionCancelled The subscription was canceled successfully. Amazon will make no further attempts to collect payment against the subscription.
#SubscriptionCompleted The subscription was completed. All payments have been collected.
#SubscriptionSuccessful The subscription was created successfully.

#ALTER TABLE `payments` CHANGE COLUMN `caller_reference` `reference_id` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL;