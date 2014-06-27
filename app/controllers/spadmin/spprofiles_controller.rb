class Spadmin::SpprofilesController < Spadmin::ResourcesController
  def index
    response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'profile', nil)
    if response.code == '200'
    @profile = ActiveSupport::JSON.decode(response.body)
    @uid = @profile["uid"]
    @name = @profile["name"]
    @emailId = @profile["emailId"]
    @featureSet = @profile["featureSet"]
    @activeStatus = @profile["activeStatus"]
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
    flash[:error]  = t("controllers.get.error.sp_profile") + "<br />" + response.body
    end
    @profile ||= ''
  end

  def update
    action = params[:commit].downcase
    case action
      when "cancel"
        redirect_to :action => :index
    else
    content_json = {"uid" => params[:id].to_i,"emailId" => params[:edit_profile][:emailId],
    "geographicDetails" => {"uid" => params[:geographicDetails][:uid].to_i,"timezone" => params[:edit_profile][:timezone],
    "zipCode" => params[:edit_profile][:zipCode],
    "locale" => params[:edit_profile][:locale],"state" => params[:edit_profile][:state],"language" => params[:edit_profile][:language],
    "addressLine2" => params[:edit_profile][:addressLine2],
    "addressLine1" => params[:edit_profile][:addressLine1],"country" => params[:edit_profile][:country],
    "city" => params[:edit_profile][:city]}}.to_json

    response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'profile', content_json)

    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.sp_profile")
    redirect_to :action => :index
    else
    flash[:error]  = t("controllers.update.error.sp_profile") + "<br />" + response.body
    redirect_to :action => :edit
    end
    end
  end

  def edit
    response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'profile', nil)
    if response.code == '200'
    @profile = ActiveSupport::JSON.decode(response.body)
    @uid = @profile["uid"]
    @name = @profile["name"]
    @emailId = @profile["emailId"]
    @featureSet = @profile["featureSet"]
    @activeStatus = @profile["activeStatus"]
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
    flash[:error]  = t("controllers.get.error.sp_profile") + "<br />" + response.body
    end
  end

end
