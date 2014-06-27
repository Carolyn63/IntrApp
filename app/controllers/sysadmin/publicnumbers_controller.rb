class Sysadmin::PublicnumbersController < Sysadmin::ResourcesController

	def index
		response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/', 'available')
		if response.code == '200'
			$public_numbers = ActiveSupport::JSON.decode(response.body)              
			flash.now[:warning]  = t("controllers.get.empty.available_publicnumbers") if $public_numbers.blank?
		else
			flash[:error]  = t("controllers.get.error.available_publicnumbers")  + "<br />" + response.body
		end
		$public_numbers ||= Array.new
		@page_results = $public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
	end

	def new
	end
	
	def assign_unassign
	   response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovider/', 'all')
      if response.code == '200'
        @serviceproviders = ActiveSupport::JSON.decode(response.body)
      else
        flash[:error]  = t("controllers.get.error.serviceproviders_list")  + "<br />" + response.body
      end
    flash.now[:warning]  = t("controllers.get.empty.serviceproviders_list") unless !@serviceproviders.blank?
    @serviceproviders ||= ''
	end

	def edit
  end
  
  def update
    logger.info("updating...............")
    if params[:operation] == "assign"
        for i in 0..(params[:row][:count].to_i - 1)
          if params[:assign][i.to_s] == true.to_s
            response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/assign/'+ params[:number][i.to_s] + '/serviceprovider/' + params[:id].to_s, nil)
            response_code = response.code
            if response.code != '200'
              do_fail =true
              flash[:error]  = t("controllers.assign.error.public_numbers")  + "<br />" + response.body
            end
          end
       end #for
       flash[:notice]  = t("controllers.assign.ok.public_numbers") unless do_fail
        redirect_to  assign_unassign_sysadmin_publicnumbers_path
    elsif params[:operation] == "unassign"
      for i in 0..(params[:row][:count].to_i - 1)
          if params[:assign][i.to_s] == true.to_s
            response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/unassign/'+ params[:number][i.to_s] + '/serviceprovider/' + params[:id].to_s, nil)
            response_code = response.code
            if response.code != '200'
              do_fail =true
              flash[:error]  = t("controllers.unassign.error.public_numbers")  + "<br />" + response.body
            end
          end
       end #for
       flash[:notice]  = t("controllers.unassign.ok.public_numbers") unless do_fail
       redirect_to  assign_unassign_sysadmin_publicnumbers_path
         
    end 
  end
  
  def assign
     @uid = params[:id]
     response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/', 'available')
        if response.code == '200'
          @public_numbers = ActiveSupport::JSON.decode(response.body)              
          flash.now[:warning]  = t("controllers.get.empty.available_public_numbers") if @public_numbers.blank?
        else
          flash[:error]  = t("controllers.get.error.available_publicnumbers")  + "<br />" + response.body
        end
      @public_numbers ||= Array.new
      @page_results = @public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
  end

	def unassign
		response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/assigned/serviceprovider/', params[:id])
		if response.code == '200'
			@public_numbers = ActiveSupport::JSON.decode(response.body)              
			flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if @public_numbers.blank?
		else
			flash[:error]  = t("controllers.get.error.assigned_publicnumbers")  + "<br />" + response.body
		end
		@public_numbers ||= Array.new
		@page_results = @public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
	end

	def create
		action = params[:commit].downcase
		case action
		when "cancel"
			redirect_to :action => :index
		else
			if params[:public_number][:range_from]!="" && params[:public_number][:range_to]==""
				content_json = {"number" => params[:public_number][:range_from]}.to_json
			else
				content_json = {"number" => params[:public_number][:range_from] + "to" + params[:public_number][:range_to]}.to_json
			end
			
			logger.info("create public number: #{content_json}");

			response = IppbxApi.ippbx_post(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber', content_json)

			if response.code == '200'
				flash[:notice]  = t("controllers.create.ok.public_numbers")
				$public_numbers = nil
				redirect_to  sysadmin_publicnumbers_path
			else
				flash[:error]  = t("controllers.create.error.public_numbers") + "<br />" + response.body
				render :action => 'new'
			end
		end
	end


	def destroy
		if !params[:id].blank?
			response = IppbxApi.ippbx_delete(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/', params[:id])
			if response.code == '200'
				$public_numbers = nil
				flash[:notice]  = t("controllers.delete.ok.public_numbers")
			else
				flash[:error]  = t("controllers.delete.error.public_numbers") + "<br />" + response.body
			end
		end
		redirect_to  sysadmin_publicnumbers_path
	end

end
