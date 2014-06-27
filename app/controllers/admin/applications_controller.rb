class Admin::ApplicationsController < Admin::ResourcesController
	actions :all

	sortable_attributes :name, :id, :approved_companies_count, :departments_count, :approved_employees_count

	def per_page; 50; end

	def sphinx_filters
	end

	def collection
		get_collection_ivar || set_collection_ivar(
		if params[:search].blank?
			end_of_association_chain.by_status(params[:status]
			).by_company_id(params[:company_id]
			).by_category_id(params[:category_id]
			).by_device_id(params[:device_id]
			).by_application_type_id(params[:application_type_id]
			).by_industry_id(params[:industry_id]
			).by_country_id(params[:country_id]
			).paginate(:page => params[:page], :per_page => per_page, :order => resource_sort_order)
		else
		#end_of_association_chain.search(params[:search], :with => sphinx_filters, :page => params[:page], :order => "name ASC", :star => true)
			end_of_association_chain.by_first_letter(params[:search]).by_status(params[:status]
			).by_company_id(params[:company_id]
			).by_category_id(params[:category_id]
			).by_device_id(params[:device_id]
			).by_application_type_id(params[:application_type_id]
			).by_industry_id(params[:industry_id]
			).by_country_id(params[:country_id]
			).paginate(:page => params[:page], :per_page => per_page, :order => resource_sort_order)
		end
		)
	end

 def binfile
 @application = Application.find_by_id(params[:id])
 device_ids = params[:device_ids].split(",")
 @devices = Device.by_ids(device_ids)
  render :partial => "binfile"
 end 


 def update_binfile
   logger.info(params[:devicefication])
   param = params[:devicefication]
   #fields = {:application_id => params[:id], :device_id =>  }
   device_ids = param[:existing_device_ids].split(",")
   device_ids.each do |device_id|
     logger.info(">>>>>>>>>#{device_id}")
     logger.info(param["bin_file#{device_id}"])
     if !param["bin_file#{device_id}"].blank?
       devicefication = Devicefication.find_by_application_id_and_device_id(params[:id], device_id)
       devicefication.update_attributes(:bin_file => param["bin_file#{device_id}"])
       logger.info("Updated????>>>>>>>>>>>>>>>.")
     end
   end
   
   new_device_ids =  param[:new_device_ids].split(",")
    new_device_ids.each do |device_id|
     logger.info(">>>>>>>>>#{device_id}")
     logger.info(param["bin_file#{device_id}"])
     fields = {:application_id => params[:id], :device_id =>device_id}
     if !param["bin_file#{device_id}"].blank?
         fields[:bin_file] = param["bin_file#{device_id}"]
     end
     new_device = Devicefication.new(fields)
     new_device.save
   end
   
   redirect_to :back
 end
  
  def deletefile
      @application = Application.find_by_id(params[:id])   
      render :partial => "deletefile"
   end
  
  def delete_binfile
    unless  params[:devicefication].blank?
    params[:devicefication][:device_ids].each do |device_id|
      devicefication = Devicefication.find_by_id(device_id)
      logger.info("devicefication =#{devicefication.application_id}")
      devicefication.remove_bin_file!
    end
    end
          redirect_to :back
  end


# New UI
	def add_downloadable_apps
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

end
