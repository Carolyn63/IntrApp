class Entadmin::EntprofilesController  < Entadmin::ResourcesController
  def index
    response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'profile', nil)
    if response.code == '200'
    @profile = ActiveSupport::JSON.decode(response.body)
    logger.info(@profile)
    @uid = @profile["enterprise"]["uid"]
    @name = @profile["enterprise"]["name"]
    @emailId = @profile["enterprise"]["emailId"]
    @featureSet = @profile["enterprise"]["featureSet"]
    @activeStatus = @profile["enterprise"]["activeStatus"]
    @state = @profile["enterprise"]["geographicDetails"]["state"]
    @city = @profile["enterprise"]["geographicDetails"]["city"]
    @country = @profile["enterprise"]["geographicDetails"]["country"]
    @timezone = @profile["enterprise"]["geographicDetails"]["timezone"]
    @locale = @profile["enterprise"]["geographicDetails"]["locale"]
    @zipCode = @profile["enterprise"]["geographicDetails"]["zipCode"]
    @language = @profile["enterprise"]["geographicDetails"]["language"]
    @addressLine1 = @profile["enterprise"]["geographicDetails"]["addressLine1"]
    @addressLine2 = @profile["enterprise"]["geographicDetails"]["addressLine2"]
    @extensionLength = @profile["enterprise"]["extensionLength"]
    @faxNumber = @profile["enterprise"]["faxNumber"]
    @website= @profile["enterprise"]["url"]
    else
    flash[:error]  = t("controllers.get.error.ent_profile") + "<br />" + response.body
    end
    @profile ||= ''
  end

  def update
    action = params[:commit].downcase
    case action
      when "cancel"
        redirect_to :action => :index
    else
    content_json = {"enterprise"=>{"uid" => params[:id].to_i,
    "name" => params[:edit_profile][:name],
    "emailId" => params[:edit_profile][:emailId],
    "faxNumber" => params[:edit_profile][:faxNumber],
    "geographicDetails" => {"uid" => params[:geographicDetails][:uid].to_i,"timezone" => params[:edit_profile][:timezone],
    "zipCode" => params[:edit_profile][:zipCode],
    "locale" => params[:edit_profile][:locale],"state" => params[:edit_profile][:state],"language" => params[:edit_profile][:language],
    "addressLine2" => params[:edit_profile][:addressLine2],
    "addressLine1" => params[:edit_profile][:addressLine1],"country" => params[:edit_profile][:country],
    "city" => params[:edit_profile][:city]},
    "url"=> params[:edit_profile][:website]    
    }}.to_json
    
    response = IppbxApi.ippbx_put(session[:ent_admin], session[:ent_pass], 'ent', 'profile', content_json)
    if response.code == '200'
    
    
    params_update_ippbx = {
    :name => params[:edit_profile][:name],
      :date_updated => Time.new.strftime("%Y-%m-%d %H:%M:%S")
    }
    
    params_update_company = {
    :name => params[:edit_profile][:name],
    :zipcode => params[:edit_profile][:zipCode],
    :state => params[:edit_profile][:state],
    :address2 => params[:edit_profile][:addressLine2],
    :address => params[:edit_profile][:addressLine1],
    :country => params[:edit_profile][:country],
    :city => params[:edit_profile][:city],
    :website => params[:edit_profile][:website], 
    :phone => params[:edit_profile][:phoneNumbers],    
    }
  
    #params_update[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
    ippbx = Ippbx.find_by_admin_type_and_uid("enterprise", params[:id].to_i)    
    Ippbx.find_by_admin_type_and_uid("enterprise", params[:id].to_i).update_attributes(params_update_ippbx)    
    Company.update(ippbx.company_id,params_update_company)
        
    flash[:notice]  = t("controllers.update.ok.ent_profile")
    redirect_to :action => :index
    else
    flash[:error]  = t("controllers.update.error.ent_profile") + "<br />" + response.body
    redirect_to :action => :edit
    end
    end
  end

  def edit
    response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'profile', nil)
    if response.code == '200'
    @profile = ActiveSupport::JSON.decode(response.body)
    @uid = @profile["enterprise"]["uid"]
    @name = @profile["enterprise"]["name"]
    @emailId = @profile["enterprise"]["emailId"]
    @featureSet = @profile["enterprise"]["featureSet"]
    @activeStatus = @profile["enterprise"]["activeStatus"]
    @state = @profile["enterprise"]["geographicDetails"]["state"]
    @city = @profile["enterprise"]["geographicDetails"]["city"]
    @country = @profile["enterprise"]["geographicDetails"]["country"]
    @timezone = @profile["enterprise"]["geographicDetails"]["timezone"]
    @locale = @profile["enterprise"]["geographicDetails"]["locale"]
    @zipCode = @profile["enterprise"]["geographicDetails"]["zipCode"]
    @language = @profile["enterprise"]["geographicDetails"]["language"]
    @addressLine1 = @profile["enterprise"]["geographicDetails"]["addressLine1"]
    @addressLine2 = @profile["enterprise"]["geographicDetails"]["addressLine2"]
    @geographic_details_uid = @profile["enterprise"]["geographicDetails"]["uid"]
    @faxNumber = @profile["enterprise"]["faxNumber"]
    @website = @profile["enterprise"]["url"]
    else
    flash[:error]  = t("controllers.get.error.ent_profile") + "<br />" + response.body
    end
  end
end
