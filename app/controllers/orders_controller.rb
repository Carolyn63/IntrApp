class OrdersController < ApplicationController
  before_filter :require_user
  before_filter :require_https, :only => [:payments]
  before_filter :require_http, :except => [:payments] 
  
  def create
  basic_order = Order.active_basic( current_user.id, params[:basic_id])
   if !basic_order.blank? and Order.pending_orders(current_user.id).blank?
	@company = current_user.employers.find current_user.companies[0].id
	if !params[:orders][:plan_id].blank?
	plan = ApplicationPlan.find_by_id(params[:orders][:plan_id])
				if params[:orders]["quantity_#{plan.id}"].present? and params[:orders]["quantity_#{plan.id}"] =~ /^[1-9]+$/
				  logger.info("11111111222")
				quantity = params[:orders]["quantity_#{plan.id}"].to_i
				order = Order.new(:requested_at => Time.now, :user_id => current_user.id, :application_id=> plan.application_id, :quantity => quantity, 
				:amount => plan.amount, :plan_id=> plan.id, :application_nature => plan.application_nature)
				if order.save
				  plan_order = Order.pending_order_by_plan(current_user.id, plan.id)[0]
					companification = @company.companifications.build(:application_id => plan.application_id, :status => Companification::Status::PENDING, :requested_at => Time.now, :plan_id => plan.id, :order_id =>plan_order.id)
					if companification.save
					
					flash[:notice] = t("controllers.create.ok.order")
					redirect_to cart_user_orders_path(current_user.id, :operation => "cart")
					else
					flash[:error] = t("controllers.create.error.order")
					redirect_to :back
					end
				
				end
				else
				  flash[:error] = t("controllers.create.error.valid_number")  
				  logger.info("1111111111111111")
				  redirect_to :back   
				end
				
      elsif params[:orders][:plan_id].blank?
	    flash[:error] = t("controllers.create.error.select_addon")   
	    logger.info("22222222222222")
	    redirect_to :back   
      end
  else
	flash[:error] = t("controllers.create.error.one_order")     
	logger.info("3333333333333333")
	redirect_to :back   
  end
         
  end

  def create_app_order
    
    @company = current_user.employers.find params[:company_id]
    @plan = ApplicationPlan.basic_plan(params[:plan_id])[0]
    logger.info("BAsic plan~~~~~~~~~#{@plan.application_id}")
    if Order.pending_orders(current_user.id).blank?
          order = Order.new(:requested_at => Time.now, :user_id => current_user.id, :application_id=> @plan.application_id, :quantity => 1, 
                            :amount => @plan.amount, :plan_id=> @plan.id, :application_nature => @plan.application_nature)
        
          if order.save
            basic_order = Order.pending_order_by_plan(current_user.id, @plan.id)[0]
            companification = @company.companifications.build(:application_id => @plan.application_id, :status => Companification::Status::PENDING, :requested_at => Time.now, :plan_id => @plan.id, :order_id =>basic_order.id, :max_employees_count =>@plan.default_employees_count)
            if companification.save
              flash[:notice] = t("controllers.create.ok.order")
              redirect_to cart_user_orders_path(current_user.id, :operation => "cart")
            else
              flash[:error] = t("controllers.create.error.order")
              redirect_to :back
            end
          end
     else
         flash[:error] = t("controllers.create.error.one_order")   
         redirect_to :back
            
    end
    
  end

  def track_order
    @orders = Order.find_all_by_user_id(current_user.id)
    if @orders.blank?
    flash[:notice] = "You have not initiated any orders."
    end
  end

  def destroy
    order = Order.find_by_id(params[:id])
    if order.destroy
    flash[:notice] = t("controllers.delete.ok.orders")
    else
     flash[:notice] = t("controllers.delete.error.orders")
    end
    redirect_to :back
  end

  def index

  end

  def cart
    @orders = Order.pending_orders(current_user.id)
    
    if @orders.blank?
    flash[:notice] = t("controllers.get.empty.orders")
    end

  end

  def payments

    if !params[:order_ids].blank?
    @orders = Order.pending_orders(current_user.id)
    @paypal_ipn_url = property(:app_site) + "/ipn/paypal/?email=" + current_user.email
    @amazon_ipn_url = property(:app_site) + "/ipn/amazon/?email=" + current_user.email
    render :layout => 'signup'
    else
    redirect_to :back
    end

  end
  
    
  def send_request plan_ids, company_id
    plan_ids.each do |plan_id|
    plan = ApplicationPlan.find_by_id(plan_id)
    @company = current_user.employers.find company_id
    logger.info(@company.name)
    logger.info("1111111111111111111111")
    request = @company.companifications.build(:application_id=> plan.application_id, :plan_id => plan.id,  :status => Companification::Status::PENDING, :requested_at => Time.now )
    request.save
    end
  end
end
