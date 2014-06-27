require 'inherited_resources'
class CompanyApplicationsController < ApplicationController
  inherit_resources
  defaults :resource_class => Application, :collection_name => 'applications', :instance_name => 'application'
  before_filter :require_user
  before_filter :find_company
  before_filter :only_owner
  before_filter :find_application, :except => [:new, :index, :create]
  sortable_attributes :name, :id
  helper_method :resource_class_as_sym,:error_messages_for_resource_comp

  def per_page; 20; end
  
  def resource_class;  Application;  end
  def collection_name;  "applications";  end
  def instance_name;  "application";  end
  
  def index
  @applications = Application.private(current_own_company.id).paginate(:page => params[:page], :per_page => per_page, :order => :id)
  end
  
  def new
  @application = Application.new()
  end
  
  def create
    params[:application][:app_type] = "private"
	params[:application][:company_id] = @company.id
    create!(:notice => "Application Created") { company_company_applications_path(current_own_company) }
  end
  
  def edit
  @application = Application.find_by_id(params[:id])
  end
  
  def update
    update!(:notice => "Application Updated") { company_company_applications_path(current_own_company) }
  end
  
  def destroy
   destroy!(:notice => "Application Deleted") { company_company_applications_path(current_own_company) }
  end

	def add_downloadable_apps
		@company = Company.find_by_id(params[:company_id])
		@application = Application.find_by_id(params[:id])
		device_ids = params[:device_ids].split(",")
		@devices = Device.by_ids(device_ids)
		render :partial => "add_downloadable_apps"
	end 

	def update_downloadable_apps
		#logger.info(params[:devicefication])
		param = params[:devicefication]
		device_ids = param[:existing_device_ids].split(",")
		device_ids.each do |device_id|
			devicefication = Devicefication.find_by_application_id_and_device_id(params[:id], device_id)
			if !param["bin_file#{device_id}"].blank? 
				devicefication.update_attributes(:bin_file => param["bin_file#{device_id}"])
			end
			if !param["download_url#{device_id}"].blank? 
				devicefication.update_attributes(:download_url => param["download_url#{device_id}"])
			end
		end

		new_device_ids =  param[:new_device_ids].split(",")
		new_device_ids.each do |device_id|
			fields = {:application_id => params[:id], :device_id =>device_id}
			if !param["bin_file#{device_id}"].blank?
				fields[:bin_file] = param["bin_file#{device_id}"]
			end
			if !param["download_url#{device_id}"].blank?
				fields[:download_url] = param["download_url#{device_id}"]
			end
			new_device = Devicefication.new(fields)
			new_device.save
		end

		redirect_to :back
	end

	def remove_downloadable_apps
		@company = Company.find_by_id(params[:company_id])
		@application = Application.find_by_id(params[:id])   
		render :partial => "remove_downloadable_apps"
	end

	def delete_downloadable_apps # check bin_file and download_url params
		logger.info("delete_downloadable_apps params:  #{params}")
		unless params[:bin_file].blank?
			params[:bin_file][:device_ids].each do |device_id|
				devicefication = Devicefication.find_by_id(device_id)
				devicefication.update_attributes(:bin_file => nil)
				devicefication.remove_bin_file!
			end
		end
		unless params[:download_url].blank?
			params[:download_url].each do |device_id, url|
				logger.info("download_url device_id:  #{device_id}")
				logger.info("download_url url:  #{url}")
				if url == ""
					devicefication = Devicefication.find_by_id(device_id)
					devicefication.update_attributes(:download_url => nil)
				end
			end
		end

		redirect_to :back
	end
	
	def list_plan
	    @application_plans = ApplicationPlan.find_all_by_application_id(@application.id).paginate(:page => params[:page], :per_page => per_page, :order => :id)
	end
	
	def create_plan
	  if params[:commit] == "Finish"
			params[:application_plan][:currency] =  property(:default_currency)
			params[:application_plan][:amount] = params[:application_plan][:amount].blank? ? 0 : params[:application_plan][:amount]
			@application_plan = ApplicationPlan.new(params[:application_plan])
			if @application_plan.save
				flash[:notice] = t("controllers.create.ok.application_plans")
				redirect_to list_plan_company_company_application_path(current_own_company, params[:application_plan][:application_id])
			else
				flash[:notice] = t("controllers.create.error.application_plans")
				redirect_to new_plan_company_company_application_path(current_own_company, params[:application_plan][:application_id])
			end
		else
			redirect_to list_plan_company_company_application_path(current_own_company, params[:application_plan][:application_id])
		end
	end
	
	def new_plan
	   @application_plan = ApplicationPlan.new()
	   @applications = Application.find_all_by_company_id(current_own_company)
	end
	
	def edit_plan
	   @application_plan = ApplicationPlan.find_by_id(params[:plan_id])
	end
	
	def update_plan
	if params[:commit] == "Finish"
			@application_plan= ApplicationPlan.find_by_id(params[:plan_id])
			unless @application_plan.blank?
				params[:application_plan][:currency] =  property(:default_currency)
				if @application_plan.update_attributes(params[:application_plan])
					flash[:notice] = t("controllers.update.ok.application_plans")
					redirect_to list_plan_company_company_application_path(current_own_company, params[:application_plan][:application_id])
				else
					flash[:notice] = t("controllers.update.error.application_plans")
					redirect_to new_plan_company_company_application_path(current_own_company, params[:application_plan][:application_id])
				end
			else
				redirect_to list_plan_company_company_application_path(current_own_company, params[:application_plan][:application_id])
			end
		else
			redirect_to list_plan_company_company_application_path(current_own_company, params[:application_plan][:application_id])
		end
	end
	
	def delete_plan
	    @application_plan= ApplicationPlan.find_by_id(params[:plan_id])
		unless @application_plan.blank?
			if @application_plan.destroy
				flash[:notice] = t("controllers.delete.ok.application_plans")
			else
				flash[:notice] =t("controllers.delete.error.application_plans")
			end
		end
		redirect_to list_plan_company_company_application_path(current_own_company, @application.id)
	end
	

    protected

  def find_company
    @company = Company.find_by_id params[:company_id]
    report_maflormed_data if @company.blank?
  end

  def only_owner
    report_maflormed_data unless @company.admin == current_user
  end
  
  def find_application
     @application = Application.find_by_id_and_app_type(params[:id], "private")
     report_maflormed_data if @application.blank?
  end
  
    def resource_sort_order
    "#{ resource_class.name.tableize }.#{ sort_order(:default => "ascending") }"
  end
  
  def error_messages_for_resource_comp
   error_messages_for_resource_comp resource_class.name.underscore.to_sym
  end
  
  def resource_class_as_sym
    resource_class.name.underscore.to_sym
  end


end
