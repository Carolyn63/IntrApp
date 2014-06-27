class Admin::StatsController < Admin::ResourcesController
  
	sortable_attributes :name,:id

	def index
		logger.info("11111111111111111111")
		redirect_to registered_linkedin_companies_admin_stats_path
	end

	def registered_companies
	end

	def registered_users
	end

	def paid_users
	end
  
	def payments
		if !params[:search].blank?
			# @users = Payment.users
			@users = User.by_first_letter(params[:search])
			@payments  ||= Array.new
			unless @users.blank?
				@users.each do |user|
					@user_payments = Payment.find_all_by_email(user.email)
					unless @user_payments.blank?
						logger.info("user_payments #{@user_payments[0].email}")
						@user_payments.each do |user_payment|
						logger.info("user email........#{}")
						@payments << user_payment
					end
				end
			end
			logger.info(">>>>>>>>>>>>>>>>>#{@payments[0].id}")
			logger.info(">>>>>>>>>>>>>>>>>#{@payments[0].id}")
			end
			@payments = @payments.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)	      
		else
			@payments = Payment.find(:all).paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
		end
		if @payments.blank?
			flash[:notice] = t("controllers.search.empty")
		end
	end

	def history
		render :partial => "history"
	end
	
	def cancel_paypal
	  unless params[:subscription_id].blank?
      response = PaypalApi.cancel_payment params
			if response == "Success"
				flash[:notice] = t("views.notices.payment_cancel_success")
			else
				flash[:notice] = t("views.notices.payment_cancel_failed")
			end
			
			redirect_to payments_admin_stats_path
		 end
	end
       
	
	def refund_paypal
	  unless params[:transaction_id].blank?
		 response = PaypalApi.refund_payment params
		 if response == "Success"
			flash[:notice] = t("views.notices.payment_refund_success")
		 else
			flash[:notice] = t("views.notices.payment_refund_failed")
		 end 
		 end
		 redirect_to payments_admin_stats_path

	end
	
	 def cancel_amazon
    unless params[:subscription_id].blank?
        response = AmazonApi.post_amazon("cancel", params[:subscription_id])
        logger.info("Amazon Response.........#{response.body}")

      if response == "Success"
        flash[:notice] = t("views.notices.payment_cancel_success")
      else
        flash[:notice] = t("views.notices.payment_cancel_failed")
      end
      
      redirect_to payments_admin_stats_path
     end
  end
       
  
  def refund_amzon
     unless params[:transaction_id].blank?
     response = AmazonApi.post_amazon("refund", params[:transaction_id])
     logger.info("Amazon Response.........#{response.body}")
     if response == "Success"
      flash[:notice] = t("views.notices.payment_refund_success")
     else
      flash[:notice] = t("views.notices.payment_refund_failed")
     end 
     end
     
     redirect_to payments_admin_stats_path

  end

	def download
		filename = params['filename']
		send_file "#{RAILS_ROOT}/public/resources/"+filename, :type => ' text/csv; charset=iso-8859-1;', :disposition => "attachment; filename="+filename
	end

end
