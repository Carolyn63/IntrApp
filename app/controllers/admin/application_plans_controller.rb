class Admin::ApplicationPlansController < Admin::ResourcesController
	before_filter :require_user, :only => [:edit]
	actions :index, :show, :edit, :update, :destroy

	sortable_attributes :id, :name, :active, :amount, :currency

	def index
		@application_plans= ApplicationPlan.find(:all, :order => "code")
		if @application_plans.blank?
			flash[:notice] =  t("controllers.get.empty.application_plans")
		end
	end
  
	def edit
	  @application = Application.find(:all)
		@application_plan= ApplicationPlan.find_by_id(params[:id])
		unless @application_plan.blank?
			@application_id = @application_plan.application_id
			@code = @application_plan.code
			@currency = @application_plan.currency
			@active = @application_plan.active
			@amount = @application_plan.amount
			@payment_type = @application_plan.payment_type
			@nature = @application_plan.application_nature
			@default_employees_count = @application_plan.default_employees_count
			@description = @application_plan.description
		end
	end
	
  
	def update
		if params[:commit] == "Finish"
			@application_plan= ApplicationPlan.find_by_id(params[:id])
			unless @application_plan.blank?
				params[:application_plan][:currency] =  property(:default_currency)
				if @application_plan.update_attributes(params[:application_plan])
					flash[:notice] = t("controllers.update.ok.application_plans")
					redirect_to admin_application_plans_path
				else
					flash[:notice] = t("controllers.update.error.application_plans")
					render :action => :edit
				end
			else
				redirect_to admin_application_plans_path
			end
		else
			redirect_to admin_application_plans_path
		end
	end

	def new
	    logger.info("111111111111111111111111")
    @application = Application.find(:all)
	end
  
	def create
		if params[:commit] == "Finish"
			params[:application_plan][:currency] =  property(:default_currency)
			params[:application_plan][:amount] = params[:application_plan][:amount].blank? ? 0 : params[:application_plan][:amount]
			@application_plan = ApplicationPlan.new(params[:application_plan])
			if @application_plan.save
				flash[:notice] = t("controllers.create.ok.application_plans")
				redirect_to admin_application_plans_path
			else
				flash[:notice] = t("controllers.create.error.application_plans")
				render :action => :new
			end
		else
			redirect_to admin_application_plans_path
		end
	end

	def destroy
		@application_plan= ApplicationPlan.find_by_id(params[:id])
		unless @application_plan.blank?
			if @application_plan.destroy
				flash[:notice] = t("controllers.delete.ok.application_plans")
			else
				flash[:notice] =t("controllers.delete.error.application_plans")
			end
		end
		redirect_to admin_application_plans_path
	end

end