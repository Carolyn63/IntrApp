class Admin::UserPaymentRequestsController < Admin::ResourcesController
  actions :index, :cancel_paypal, :refund_paypal

  sortable_attributes :requested_at, :payment => "payments.id", :user => "users.name"

  def cancel_paypal
    response = PaypalApi.cancel_payment params
    logger.info("paypal>>>>>>>>>>>#{response}")
    if response == "Success"
      resource.approve!
      flash[:notice] = t("views.notices.payment_cancel_success")
    else
      resource.fail!
       flash[:notice] = t("views.notices.payment_cancel_failed")
    end
    redirect_to admin_user_payment_requests_path
  end

  def refund_paypal
    response = PaypalApi.refund_payment params
    if response == "Success"
      resource.approved!
       flash[:notice] = t("views.notices.payment_refund_success")
      
    else
       resource.fail!
       flash[:notice] = t("views.notices.payment_refund_failed")
    end
    redirect_to admin_company_application_requests_path
  end
  
  def cancel_amazon
    logger.info("111111111111111111111111")
    response = AmazonApi.post_amazon("cancel", params[:subscription_id])
    logger.info("Amazon......#{response.code}")
    logger.info("Amazon......#{response.message}")
    response = response.message
    if response == "Success"
      resource.approve!
      flash[:notice] = t("views.notices.payment_cancel_success")
   
    else
      resource.fail!
        flash[:notice] = t("views.notices.payment_cancel_failed")
    end
    redirect_to admin_user_payment_requests_path
  end

  def refund_amazon
    response = AmazonApi.post_amazon("refund", params[:transaction_id])
    if response == "Success"
      resource.approved!
       flash[:notice] = t("views.notices.payment_refund_success")
    else
       resource.fail!
       flash[:notice] = t("views.notices.payment_refund_failed")
    end
    redirect_to admin_company_application_requests_path
  end
  
  
  def payment
    render :partial => "payment"
  end
  
  


  protected

  def resource_class
    UserRequest
  end

  def collection
    get_collection_ivar || set_collection_ivar(
      UserRequest.pending.paginate(:page => params[:page], :order => sort_order(:default => "descending"))
    )
  end

  def resource
    @request ||= UserRequest.find(params[:id])
  end
end
