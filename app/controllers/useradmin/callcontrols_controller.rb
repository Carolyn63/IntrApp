class Useradmin::CallcontrolsController < Useradmin::ResourcesController
  def index
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'features/', 'all')
    if response.code == '200'
    @features = ActiveSupport::JSON.decode(response.body)
    else
    flash[:error]  = t("controllers.get.error.assigned_features") + "<br />" + response.body
    end
  end

  def edit
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'features/', 'all')
    if response.code == '200'
    @features = ActiveSupport::JSON.decode(response.body)
    else
    flash[:error]  = t("controllers.get.error.user_call_control") + "<br />" + response.body
    end
  end

  def update_find_me_follow_me
    content_json =  {"featureCode" => "SIMR", "active" => false}.to_json
    response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)    
    find_me_follow_me_numbers = params["find_me_follow_me_list"]
    find_me_follow_me_number = ""
    find_me_follow_me_numbers .each do |number|
    find_me_follow_me_number += number + ","  
    end
    find_me_follow_me_number = find_me_follow_me_number.chop
    logger.info "-=-=-=-=-=&&-=#{find_me_follow_me_number}"
    content_json =  {"featureCode" => "FMFM", "active" => true,  "featureRecord" => {"number" => find_me_follow_me_number, "treatment" => "User is Busy"}}.to_json
    response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)
    logger.info "Put Json Content:  #{content_json}"
    if response.code == '200'
    flash[:warning]  = "Update Sucessfully. Simutaneous Ring is disabled while Find Me Follow Me is enabled"
    #flash[:notice]  = t("controllers.update.ok.user_call_control")
    else
    flash[:error]  = t("controllers.update.error.user_call_control")  + "<br />" + response.body
    end
    
    redirect_to edit_useradmin_callcontrol_path(session[:user_admin_id])
  end

  def update_simultaneous_ring
    content_json =  {"featureCode" => "FMFM", "active" => false}.to_json
    response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)
    simultaneous_ring_numbers = params["simultaneous_ring_list"]
    simultaneous_ring_number = ""
    simultaneous_ring_numbers .each do |number|
     simultaneous_ring_number += number + ","
    end
    simultaneous_ring_number = simultaneous_ring_number.chop
    logger.info "-=-=-=-=-=&&-=#{simultaneous_ring_number}"
    content_json =  {"featureCode" => "SIMR", "active" => true,  "featureRecord" => {"number" => simultaneous_ring_number, "treatment" => "User is Busy"}}.to_json
    response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)
    logger.info "Put Json Content:  #{content_json}"
    if response.code == '200'
    #flash[:notice]  = t("controllers.update.ok.user_call_control")
    flash[:warning]  = "Update Sucessfully. Find Me Follow Me is disabled while Simutaneous Ring is enabled"
    else
    flash[:error]  = t("controllers.update.error.user_call_control")  + "<br />" + response.body
    end
   
    redirect_to edit_useradmin_callcontrol_path(session[:user_admin_id])
  end


  def update_call_block
    block_numbers = params["call_block_list"]
    block_number = ""
    block_numbers .each do |number|
    block_number += number + "," 
    end
    block_number = block_number.chop
      logger.info "-=-=-=-=-=&&-=#{block_number}"
      content_json =  {"featureCode" => "CB", "active" => true,  "featureRecord" => {"number" => block_number, "treatment" => "User is Busy"}}.to_json
      response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)
      logger.info "Put Json Content:  #{content_json}"
      if response.code == '200'
      flash[:notice]  = t("controllers.update.ok.user_call_control")
      else
      flash[:error]  = t("controllers.update.error.user_call_control")  + "<br />" + response.body
      end
    
    redirect_to edit_useradmin_callcontrol_path(session[:user_admin_id])
  end

  def update_mobile_profile
    #phone number example +18987978987
    content_json =  {"featureCode" => "MOBP","active" => true,"featureRecord" => {"number" => params["mobile_profile"]["number"], "treatment" => "User is Busy"}}.to_json
    response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)
    logger.info "Put Json Content:  #{content_json}"
    logger.info "Call Forward Busy Number: " + params["mobile_profile"]["number"]
    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.user_call_control")
    else
    flash[:error]  = t("controllers.update.error.user_call_control")  + "<br />" + response.body
    end
    redirect_to edit_useradmin_callcontrol_path(session[:user_admin_id])
  end


  def update_call_fwdbusy
    #phone number example +18987978987
    content_json =  {"featureCode" => "CFB","active" => true,"featureRecord" => {"number" => params["call_fwdbusy"]["number"], "treatment" => "User is Busy"}}.to_json
    response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)
    logger.info "Put Json Content:  #{content_json}"
    logger.info "Call Forward Busy Number: " + params["call_fwdbusy"]["number"]
    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.user_call_control")
    else
    flash[:error]  = t("controllers.update.error.user_call_control")  + "<br />" + response.body
    end
    redirect_to edit_useradmin_callcontrol_path(session[:user_admin_id])
  end

  def update_call_fwdnoans
    content_json =  {"featureCode" => "CFNA","active" => true,"featureRecord" => {"number" => params["call_fwdnoans"]["number"], "treatment" => "User is Busy"}}.to_json
    response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)
    logger.info "Put Json Content:  #{content_json}"
    logger.info "Call Forward No Answer Number: " + params["call_fwdnoans"]["number"]
    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.user_call_control")
    else
    flash[:error]  = t("controllers.update.error.user_call_control")  + "<br />" + response.body
    end
    redirect_to edit_useradmin_callcontrol_path(session[:user_admin_id])
  end

  def update_call_fwduncondition
    content_json =  {"featureCode" => "CFU","active" => true,"featureRecord" => {"number" => params["call_fwduncondition"]["number"], "treatment" => "User is Busy"}}.to_json
    response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)
    logger.info "Put Json Content:  #{content_json}"
    logger.info "Call Forward Unconditional Number: " + params["call_fwduncondition"]["number"]
    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.user_call_control")
    else
    flash[:error]  = t("controllers.update.error.user_call_control")  + "<br />" + response.body
    end
    redirect_to edit_useradmin_callcontrol_path(session[:user_admin_id])
  end

  def update_call_control_others
    for i in 0..(params[:row][:count].to_i - 1)
      content_json = {"featureCode" =>  params[:featureCode][i.to_s] ,"active" =>  params[:assign][i.to_s] }.to_json
      response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'feature/record', content_json)
      logger.info "Put Json Content:  #{content_json}"
      if response.code != '200'
      do_fail ||= true
      flash[:error]  = t("controllers.update.error.user_call_control")  + "<br />" + response.body
      break
      end

    end
    redirect_to :action => :edit and return if do_fail
    flash[:notice]  = t("controllers.update.ok.user_call_control") and redirect_to :action => :index and return unless do_fail
  end
  
  
  def edit_find_me_follow_me
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'features/', 'findmefollowme')
    if response.code == '200'
    @features = ActiveSupport::JSON.decode(response.body)
    @feature_number = @features[0]["number"].split(",")
    logger.info(@features)
    else
    flash.now[:error]  = t("controllers.get.error.user_call_control") + "<br />" + response.body
    end
    @features ||= ""
    @feature_number||= ""
    render :partial => "find_me_follow_me"
  end
  
  def edit_simultaneous_ring
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'features/', 'simultaneuosring')
    if response.code == '200'
    @features = ActiveSupport::JSON.decode(response.body)
    @feature_number = @features[0]["number"].split(",")
    else
    flash.now[:error]  = t("controllers.get.error.user_call_control") + "<br />" + response.body
    end
    @features ||= ""
    @feature_number||= ""
    render :partial => "simultaneous_ring"
  end
  
  def edit_call_block
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'features/', 'callblock')
    if response.code == '200'
    @features = ActiveSupport::JSON.decode(response.body)
    @feature_number = @features[0]["number"].split(",")
    else
    flash.now[:error]  = t("controllers.get.error.user_call_control") + "<br />" + response.body
    end
    @features ||= ""
    @feature_number||= ""
    render :partial => "call_block"
  end

  def edit_mobile_profile
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'features/', 'mobileprofile')
    if response.code == '200'
      @features = ActiveSupport::JSON.decode(response.body)
      @features.each do |feature|
        @number = feature["number"]
      end
    else
    flash.now[:error]  = t("controllers.get.error.user_call_control") + "<br />" + response.body
    end
    render :partial => "mobile_profile"
  end


  def edit_call_fwdbusy
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'features/', 'callforwardbusy')
    if response.code == '200'
      @features = ActiveSupport::JSON.decode(response.body)
      @features.each do |feature|
        @number = feature["number"]
      end
    else
    flash.now[:error]  = t("controllers.get.error.user_call_control") + "<br />" + response.body
    end
    render :partial => "call_fwdbusy"
  end

  def edit_call_fwdnoans
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'features/', 'callforwardingnoanswer')
    if response.code == '200'
      @features = ActiveSupport::JSON.decode(response.body)
      @features.each do |feature|
        @number = feature["number"]
      end
    else
    flash.now[:error]  = t("controllers.get.error.user_call_control") + "<br />" + response.body
    end
    render :partial => "call_fwdnoans"
  end

  def edit_call_fwduncondition
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'features/', 'callforwardingunconditional')
    if response.code == '200'
      @features = ActiveSupport::JSON.decode(response.body)
      @features.each do |feature|
        @number = feature["number"]
      end
    else
    flash.now[:error]  = t("controllers.get.error.user_call_control") + "<br />" + response.body
    end
    render :partial => "call_fwduncondition"
  end

end

