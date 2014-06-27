class Spadmin::AdminprofilesController < Spadmin::ResourcesController
  def index
    response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'admin/profile', nil)
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
    else
    flash[:error]  = t("controllers.get.error.sp_admin_profile") + "<br />" + response.body
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
      response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'admin/profile', content_json)
      if response.code == '200'
        begin
          IppbxNotifier.deliver_sp_admin_self_password_reset(params[:loginName][:name], params[:change_password][:password], params[:emailId][:id]) unless params[:emailId][:id].blank?
        rescue
        logger.info "Sending email to newly-created service provider admin has failed!"
        end
        # unless params[:empid].blank?
          # Employee.update(params[:empid],{:is_ippbx_enabled => 0, :ippbx_id => "",:public_number => "", :extension => ""})
        # ActiveRecord::Base.connection.execute("Delete from ippbxes where uid="+params[:id].to_s)
        #end
      flash[:notice]  = t("controllers.update.ok.password")
      else
      flash[:error]  = t("controllers.update.error.password") + "<br />" + response.body
      end
      session[:sp_admin] = nil
      session[:sp_pass] = nil
      redirect_to edit_spadmin_adminprofile_path(params[:id])
    else
    content_json = {"uid" => params[:id].to_i,"emailId" => params[:edit_profile][:emailId],
    "geographicDetails" => {"uid" => params[:geographicDetails][:uid].to_i,"timezone" => params[:edit_profile][:timezone],
    "zipCode" => params[:edit_profile][:zipCode],
    "locale" => params[:edit_profile][:locale],"state" => params[:edit_profile][:state],"language" => params[:edit_profile][:language],
    "addressLine2" => params[:edit_profile][:addressLine2],
    "addressLine1" => params[:edit_profile][:addressLine1],"country" => params[:edit_profile][:country],
    "city" => params[:edit_profile][:city]}}.to_json

    logger.info "Putting Json String: #{content_json.to_s}"

    response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'admin/profile', content_json)

    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.sp_admin_profile")
    redirect_to :action => :index
    else
    flash[:error]  = t("controllers.update.error.sp_admin_profile") + "<br />" + response.body
    redirect_to :action => :edit
    end
    end
  end

  def edit
    response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'admin/profile', nil)
    logger.info "-------------------===============#{response.body.to_s}"
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
    else
    flash[:error]  = t("controllers.get.error.sp_admin_profile") + "<br />" + response.body
    end
  end

  def change_password
    # response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'admin/profile', nil)
    # @profile = ActiveSupport::JSON.decode(response.body)
    # @emailId = @profile["emailId"]
    # @loginName = @profile["loginName"]
    render :partial=>"change_password"
  end

end
