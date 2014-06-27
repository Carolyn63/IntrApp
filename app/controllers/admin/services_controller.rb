class Admin::ServicesController < Admin::ResourcesController
   before_filter :require_user, :only => [:edit]
   actions :index, :show, :edit, :update, :destroy
  
    sortable_attributes :id, :name, :active, :amount, :currency
  def index
    @services= Service.find(:all)
    if @services.blank?
     flash[:notice] =  t("controllers.get.empty.services")
     
    end
  end
  
  def edit
    
    @service = Service.find_by_id(params[:id])
    unless @service.blank?
      @name = @service.name
      @currency = @service.currency
      @active = @service.active
      @amount = @service.amount
      @service_code = @service.service_code
    end
    
  end
  
	def update
		if params[:commit] == "Finish"
			logger.info(@service)
			@service = Service.find_by_id(params[:id])
			unless @service.blank?
			        params[:service][:currency] =  property(:default_currency)
				if @service.update_attributes(params[:service])
					flash[:notice] = t("controllers.update.ok.services")
					redirect_to admin_services_path
				else
					flash[:notice] = t("controllers.update.error.services")
					render :action => :edit
				end
			else
				redirect_to admin_services_path
			end
		else
			redirect_to admin_services_path
		end
	end
  
  def new
    
  end
  
  def create
        if params[:commit] == "Finish"
	  params[:service][:currency] =  property(:default_currency)
          @services_type = Service.new(params[:service])
          if @services_type.save
            flash[:notice] = t("controllers.create.ok.services")
            redirect_to admin_services_path
          else
            flash[:notice] = t("controllers.create.error.services")
            render :action => :new
          end
        else
          redirect_to admin_services_path
        end
        
  end
  
  def destroy
      @service = Service.find_by_id(params[:id])
      unless @service.blank?
        if @service.destroy
        flash[:notice] = t("controllers.delete.ok.services")
        else
        flash[:notice] =t("controllers.delete.error.services")
        end
      end
       redirect_to admin_services_path
      
  end
  
end
