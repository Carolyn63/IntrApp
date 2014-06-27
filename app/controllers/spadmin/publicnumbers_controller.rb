class Spadmin::PublicnumbersController < Spadmin::ResourcesController

	def index
   response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'enterprise/', 'all')
   if response.code == '200'
      @enterprises = ActiveSupport::JSON.decode(response.body)
      @public_numbers ||= Array.new
      @enterprises.each do |enterprise| 

        @entcred = Ippbx.find_by_admin_type_and_uid("enterprise", enterprise["uid"].to_s)
        ent_username = @entcred.login unless @entcred.blank?
        ent_password = Tools::AESCrypt.new.decrypt(@entcred.password) unless @entcred.blank?
         response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/assigned/enterprise/', enterprise["uid"].to_s)
        #response = IppbxApi.ippbx_get(ent_username, ent_password,'ent', 'publicnumber/', 'all')
        if  response.code == "200" 
      
         @public_numbers[enterprise["uid"]] = ActiveSupport::JSON.decode(response.body)
        end 
      end
      else
      flash[:error]  = t("controllers.get.error.enterprises_list")  + "<br />" + response.body
      end
    flash.now[:warning]  = t("controllers.get.empty.enterprises_list") unless !@enterprises.blank?
    @enterprises ||= ''
	end

  def update
    action = params[:commit].downcase
    case action
    when "cancel"
      redirect_to :action => :index
    else
    logger.info("updating...............")
    if params[:operation] == "assign"
        for i in 0..(params[:row][:count].to_i - 1)
          if params[:assign][i.to_s] == true.to_s
            response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass],'sp', 'publicnumber/assign/'+ params[:number][i.to_s] + '/enterprise/' + params[:id].to_s, nil)
            response_code = response.code
            if response.code != '200'
              do_fail =true
              flash[:error]  = t("controllers.assign.error.public_numbers")
            end
          end
        
       end #for
       flash[:notice]  = t("controllers.assign.ok.public_numbers") unless do_fail
       redirect_to  spadmin_publicnumbers_path
    elsif params[:operation] == "unassign"
      for i in 0..(params[:row][:count].to_i - 1)
          if params[:assign][i.to_s] == true.to_s
            response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass],'sp', 'publicnumber/unassign/'+ params[:number][i.to_s] + '/enterprise/' + params[:id].to_s, nil)
            response_code = response.code
            if response.code != '200'
              do_fail =true
              flash[:error]  = t("controllers.unassign.error.public_numbers")  
            end
          end
       end #for
       flash[:notice]  = t("controllers.unassign.ok.public_numbers") unless do_fail
       redirect_to  spadmin_publicnumbers_path
       end 
    end 
  end
  
  def assign

        @entcred = Ippbx.find_by_admin_type_and_uid("enterprise", params[:id].to_s)
        @company_id = @entcred.company_id unless @entcred.blank?
        response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass],'sp', 'publicnumber/', 'available')
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

    @entcred = Ippbx.find_by_admin_type_and_uid("enterprise", params[:id].to_s)
    ent_username = @entcred.login unless @entcred.blank?
    ent_password = Tools::AESCrypt.new.decrypt(@entcred.password) unless @entcred.blank?
	  response = IppbxApi.ippbx_get(ent_username, ent_password,'ent', 'publicnumber/', 'available')
    if response.code == '200'
    @public_numbers = ActiveSupport::JSON.decode(response.body)              
    flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if @public_numbers.blank?
    else
     flash[:error]  = t("controllers.get.error.assigned_publicnumbers")  + "<br />" + response.body
    end
      @public_numbers ||= Array.new
      @page_results = @public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)



	end
	def employees
	    @ent_id = params[:id]
	    logger.info("id00000000000#{params[:id]}")
	    @entcred = Ippbx.find_by_admin_type_and_uid("enterprise", params[:id].to_s)
      ent_username = @entcred.login unless @entcred.blank?
      ent_password = Tools::AESCrypt.new.decrypt(@entcred.password) unless @entcred.blank?
      response = IppbxApi.ippbx_get(ent_username, ent_password, 'ent', 'user/', 'all')
      if response.code == '200'
      @public_numbers ||= Array.new
      @employees = ActiveSupport::JSON.decode(response.body)
      @employees.each do |employee|
       employee_id = employee["userTbl"]["uid"].to_s
       active_response = IppbxApi.ippbx_get(ent_username, ent_password,'ent', 'publicnumber/assigned/user/',employee["userTbl"]["uid"].to_s)
       if active_response.code == "200"
           #@public_numbers[enterprise["uid"]] = ActiveSupport::JSON.decode(response.body)
         logger.info( ActiveSupport::JSON.decode(active_response.body))
         @public_numbers[employee["userTbl"]["uid"]] = ActiveSupport::JSON.decode(active_response.body)
       end
      end
      flash.now[:warning]  = t("controllers.get.empty.users_list") if @employees.blank?
      else
      flash[:error]  = t("controllers.get.error.users_list") + "<br />" + response.body
      end
      @employees ||= ''
	end
	
	def employee_assign

        @ent_id = params[:enterprise_id]
        @uid = params[:id]
        logger.info("ent_id ---------------#{params[:enterprise_id]}")
        @entcred = Ippbx.find_by_admin_type_and_uid("enterprise", params[:enterprise_id].to_s)
        ent_username = @entcred.login unless @entcred.blank?
        ent_password = Tools::AESCrypt.new.decrypt(@entcred.password) unless @entcred.blank?

        response = IppbxApi.ippbx_get(ent_username, ent_password,'ent', 'publicnumber/assigned/user/', params[:id].to_s)
        if response.code == "200"
          @old_number = ActiveSupport::JSON.decode(response.body)   
        end
        response = IppbxApi.ippbx_get(ent_username, ent_password,'ent', 'publicnumber/', 'available')
        logger.info("2222222222222222222222")
        if response.code == '200'
          @public_numbers = ActiveSupport::JSON.decode(response.body)              
          flash.now[:warning]  = t("controllers.get.empty.available_public_numbers") if @public_numbers.blank?
        else
          flash[:error]  = t("controllers.get.error.available_publicnumbers")  + "<br />" + response.body
        end
        @public_numbers ||= Array.new
        @page_results = @public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
	end
	
	def employee_unassign
	   @ent_id = params[:enterprise_id]
     @uid = params[:id]
     logger.info("ent_id ---------------#{params[:enterprise_id]}")
     @entcred = Ippbx.find_by_admin_type_and_uid("enterprise", params[:enterprise_id].to_s)
     ent_username = @entcred.login unless @entcred.blank?
     ent_password = Tools::AESCrypt.new.decrypt(@entcred.password) unless @entcred.blank?
	   response = IppbxApi.ippbx_get(ent_username, ent_password,'ent', 'publicnumber/assigned/user/', params[:id].to_s)
     if response.code == '200'
     @public_numbers = ActiveSupport::JSON.decode(response.body)
     flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if @public_numbers.blank?
     else
     flash[:error]  = t("controllers.get.error.assigned_public_numbers") + "<br />" + response.body
     end
      @public_numbers ||= Array.new
      @page_results = @public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
	end
	
	def employee_update
	  action = params[:commit].downcase
    case action
    when "cancel"
      redirect_to :action => :employees, :id => params[:enterprise][:id].to_s
    else
	  @entcred = Ippbx.find_by_admin_type_and_uid("enterprise", params[:enterprise][:id].to_s)
    ent_username = @entcred.login unless @entcred.blank?
    ent_password = Tools::AESCrypt.new.decrypt(@entcred.password) unless @entcred.blank?
    @usercred = Ippbx.find_by_admin_type_and_uid("user", params[:id].to_s)
	  if params[:operation] == "assign" and !params[:assign].blank?
	  @new_number = params[:assign][:pnumber] unless params[:assign][:pnumber].blank?
	  IppbxApi.ippbx_put(ent_username, ent_password, 'ent', 'publicnumber/unassign/'+ params[:assigned_public_number] + '/user/' + params[:id].to_s, nil) unless params[:assigned_public_number].blank?
	  response = IppbxApi.ippbx_put(ent_username, ent_password, 'ent', 'publicnumber/assign/'+ @new_number + '/user/' + params[:id].to_s, nil)
    logger.info ":assigned_public_number: #{params[:assigned_public_number]}"
    if response.code == '200'
    params_update = {:public_number => @new_number}
    Ippbx.update_employee_ippbx params_update,@usercred.employee_id unless @usercred.blank?
    flash[:notice]  = t("controllers.update.ok.assigned_public_numbers")
    redirect_to  employees_spadmin_publicnumber_path(params[:enterprise][:id])
    else
    flash[:error]  = t("controllers.update.error.assigned_public_numbers")
    redirect_to  employees_spadmin_publicnumber_path(params[:enterprise][:id])
    end
    elsif params[:operation] == "unassign" and !params[:unassign].blank?
    response = IppbxApi.ippbx_put(ent_username, ent_password, 'ent', 'publicnumber/unassign/'+ params[:unassign][:pnumber] + '/user/' + params[:id].to_s, nil)
    if response.code == '200'
    params_update = {:public_number => ""}
    Ippbx.update_employee_ippbx params_update,@usercred.employee_id unless @usercred.blank?
    flash[:notice]  = t("controllers.unassign.ok.public_numbers")
    redirect_to  employees_spadmin_publicnumber_path(params[:enterprise][:id])
    else
    flash[:error]  = t("controllers.unassign.error.public_numbers")  
    redirect_to  employees_spadmin_publicnumber_path(params[:enterprise][:id])
    end
    else
    redirect_to  employees_spadmin_publicnumber_path(params[:enterprise][:id])
    end
  end
  end
  
	
end
