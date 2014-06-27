class Entadmin::AdminprofilesController  < Entadmin::ResourcesController
  def index
    response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'admin/profile', nil)
    if response.code == '200'
    @profile = ActiveSupport::JSON.decode(response.body)
    @uid = @profile["uid"]
    @loginName = @profile["loginName"]
    @emailId = @profile["emailId"]
    @state = @profile["geographicDetails"]["state"]
    @city = @profile["geographicDetails"]["city"]
    @country = @profile["geographicDetails"]["country"]
    @timezone = @profile["geographicDetails"]["timezone"]
    @locale = @profile["geographicDetails"]["locale"]
    @zipCode = @profile["geographicDetails"]["zipCode"]
    @language = @profile["geographicDetails"]["language"]
    @addressLine1 = @profile["geographicDetails"]["addressLine1"]
    @addressLine2 = @profile["geographicDetails"]["addressLine2"]
    @emailHost =  @profile["emailHost"]
    @emailPort =  @profile["emailPort"]
    else
    flash[:error]  = t("controllers.get.error.ent_admin_profile") + "<br />" + response.body
    end
    @profile ||= ''
  end


  def update
    action = params[:commit].downcase
    case action
    when "cancel"
      redirect_to :action => :index
    when "change"
      content_json = {"uid" => params[:id].to_i, "password" => params[:change_password][:password], "emailId" => params[:emailId][:id]}.to_json
      response = IppbxApi.ippbx_put(session[:ent_admin], session[:ent_pass], 'ent', 'admin/profile', content_json)
      if response.code == '200'
        logger.info "========Self-Change Password Sucessully!========"
        logger.info "Location: Enterprise Admin"
        logger.info "New password: #{params[:change_password][:password]}"      
        encrypt_password = Tools::AESCrypt.new.encrypt(params[:change_password][:password])
        params_fields = {:password => encrypt_password }
        params_fields[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
        Ippbx.update_enterprise_password params_fields, session[:ippbx_ent_id].to_s
        #ActiveRecord::Base.connection.execute("update ippbxes set password=AES_ENCRYPT('"+params[:change_password][:password].to_s+"','"+property(:cryptpass).to_s+"') where admin_type='enterprise' and uid="+session[:ippbx_ent_id].to_s)           
        ippbx = Ippbx.find_by_admin_type_and_uid("enterprise",session[:ippbx_ent_id].to_s)
        company = Company.find(ippbx.company_id)
        user = User.find(company.user_id)
        begin
          IppbxNotifier.deliver_ent_admin_self_password_reset(params[:loginName][:name], params[:change_password][:password], params[:emailId][:id]) unless params[:emailId][:id].blank?
          IppbxNotifier.deliver_ent_admin_self_password_reset(params[:loginName][:name], params[:change_password][:password], user.employees[0].company_email)
	rescue
        logger.error "========Email Sending Failed!========"
        logger.error "Location: enterprise self-change password"                
        end
      flash[:notice]  = t("controllers.update.ok.password")
      else
        logger.error "========Self-Change Password Failed!========"
        logger.error "Location: Enterprise Admin"
        logger.error "Failure reason: #{response.body}"                   
      flash[:error]  = t("controllers.update.error.password") + "<br />" + response.body
      end
      session[:ent_admin] = nil
      session[:ent_pass] = nil
      redirect_to edit_entadmin_adminprofile_path(params[:id])
    else
    content_json = {"uid" => params[:id].to_i,"emailHost" =>params[:edit_profile][:emailHost],"emailPort" => params[:edit_profile][:emailPort],
     "emailPassword" =>params[:edit_profile][:emailPassword],"emailId" => params[:edit_profile][:emailId],
    "geographicDetails" => {"uid" => params[:geographicDetails][:uid].to_i,"timezone" => params[:edit_profile][:timezone],
    "zipCode" => params[:edit_profile][:zipCode],
    "locale" => params[:edit_profile][:locale],"state" => params[:edit_profile][:state],"language" => params[:edit_profile][:language],
    "addressLine2" => params[:edit_profile][:addressLine2],
    "addressLine1" => params[:edit_profile][:addressLine1],"country" => params[:edit_profile][:country],
    "city" => params[:edit_profile][:city]}}.to_json
    
    response = IppbxApi.ippbx_put(session[:ent_admin], session[:ent_pass], 'ent', 'admin/profile', content_json)

    if response.code == '200'
    email_password = Tools::AESCrypt.new.encrypt(params[:edit_profile][:emailPassword])
    params_fields = {:email_host => params[:edit_profile][:emailHost], :email_port => params[:edit_profile][:emailPort], :email_password => email_password}
    params_fields[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
    Ippbx.update_enterprise_password params_fields, session[:ippbx_ent_id].to_s
    flash[:notice]  = t("controllers.update.ok.ent_admin_profile")
    redirect_to :action => :index
    else
    flash[:error]  = t("controllers.update.error.ent_admin_profile") + "<br />" + response.body
    redirect_to :action => :edit
    end
    end
  end

  def edit
    response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'admin/profile', nil)
    if response.code == '200'
    @profile = ActiveSupport::JSON.decode(response.body)
    @uid = @profile["uid"]
    @loginName = @profile["loginName"]
    @emailId = @profile["emailId"]
    @state = @profile["geographicDetails"]["state"]
    @city = @profile["geographicDetails"]["city"]
    @country = @profile["geographicDetails"]["country"]
    @timezone = @profile["geographicDetails"]["timezone"]
    @locale = @profile["geographicDetails"]["locale"]
    @zipCode = @profile["geographicDetails"]["zipCode"]
    @language = @profile["geographicDetails"]["language"]
    @addressLine1 = @profile["geographicDetails"]["addressLine1"]
    @addressLine2 = @profile["geographicDetails"]["addressLine2"]
    @geographic_details_uid = @profile["geographicDetails"]["uid"]
    ippbx = Ippbx.find_by_login_and_admin_type(session[:ent_admin], "enterprise")
    logger.info("uid ............#{@profile["uid"]}")
    @emailHost =  ippbx.email_host
    @emailPort =  ippbx.email_port
    @emailPassword = Tools::AESCrypt.new.decrypt(ippbx.email_password)
    else
    flash[:error]  = t("controllers.get.error.ent_admin_profile") + "<br />" + response.body
    end
  end

  def change_password
    # response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'admin/profile', nil)
    # @profile = ActiveSupport::JSON.decode(response.body)
    # @emailId = @profile["emailId"]
    # @loginName = @profile["loginName"]
    render :partial=>"change_password"
  end

end
