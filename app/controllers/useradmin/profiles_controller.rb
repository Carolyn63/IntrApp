class Useradmin::ProfilesController <Useradmin::ResourcesController
  def index
    #@uid ='1'

    # {"uid":175,"userTbl":{"uid":174,"alias":"john","featureSet":"1011111111","activeStatu
    # s":true,"password":"0f731ed4eeab9892d8c0aebe43845165","featureStatus":"00000
    # 00000","loginName":"front
    # office"},"middleName":null,"lastName":"doe","workExtension":"2000","cellNumber":
    # "32432432","homePhone":"33434343","emailId":"john@huawei.com","title":"mr","f
    # axNumber":"34234","geographicDetails":{"uid":256,"timezone":"IST","locale":"en","zi
    # pCode":"560034","state":"Karnataka","language":"English","addressLine2":"Kodihally
    # ","addressLine1":"Old Airport Road","country":"United
    # States","city":"Bangalore"},"firstName":" john","workPhone":"808080808"}
    

    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'profile', nil)
    if response.code == '200'
    @profile = ActiveSupport::JSON.decode(response.body)
    @uid = @profile["uid"]
    logger.info("UID??>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#{@uid}")
    @emailId = @profile["emailId"]  
    @userTbl_uid = @profile["userTbl"]["uid"]
    @alias = @profile["userTbl"]["alias"]
    @featureSet = @profile["userTbl"]["featureSet"]
    @activeStatus = @profile["userTbl"]["activeStatus"]
    @featureStatus = @profile["userTbl"]["featureStatus"]
    @loginName = @profile["userTbl"]["loginName"]
    @middleName = @profile["middleName"]
    @lastName = @profile["lastName"]
    @workExtension = @profile["workExtension"]
    @cellNumber = @profile["cellNumber"]
    @homePhone = @profile["homePhone"]
    @title = @profile["title"]
    @faxNumber = @profile["faxNumber"]
    @firstName = @profile["firstName"]
    @workPhone = @profile["workPhone"]
    @geographicDetails_uid = @profile["geographicDetails"]["uid"]
    @timezone = @profile["geographicDetails"]["timezone"]
    @locale = @profile["geographicDetails"]["locale"]
    @zipCode = @profile["geographicDetails"]["zipCode"]
    @state = @profile["geographicDetails"]["state"]
    @language = @profile["geographicDetails"]["language"]
    @addressLine1 = @profile["geographicDetails"]["addressLine1"]
    @addressLine2 = @profile["geographicDetails"]["addressLine2"]
    @city = @profile["geographicDetails"]["city"]
    @country = @profile["geographicDetails"]["country"]
    else
    flash[:error]  = t("controllers.get.error.user_profile") + "<br />" + response.body
    end
    @profile ||= ''
  end

  def update
    action = params[:commit].downcase
    case action
    when "cancel"
      redirect_to :action => :index
    when "change"
      content_json = {"uid" => params[:id].to_i, "userTbl" => {"uid" => session[:user_admin_id], "password" => params[:change_password][:password]}, "emailId" => params[:emailId][:id]}.to_json
      response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'profile', content_json)
      if response.code == '200'
      encrypt_password = Tools::AESCrypt.new.encrypt(params[:change_password][:password])
      params_fields = {:password => encrypt_password }
      params_fields[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
      Ippbx.update_employee_password params_fields, session[:user_admin_id]
      #ActiveRecord::Base.connection.execute("update ippbxes set password=AES_ENCRYPT('"+params[:change_password][:password].to_s+"','"+property(:cryptpass).to_s+"') where admin_type='user' and uid="+session[:user_admin_id].to_s)
      ippbx = Ippbx.find_by_admin_type_and_uid("user", session[:user_admin_id].to_s) 
      employee = Employee.find(ippbx.employee_id)
      IppbxNotifier.deliver_user_admin_self_password_reset(params[:loginName][:name], params[:change_password][:password], params[:emailId][:id]) unless params[:emailId][:id].blank?
      IppbxNotifier.deliver_user_admin_self_password_reset(params[:loginName][:name], params[:change_password][:password], employee.company_email)
      flash[:notice]  = t("controllers.update.ok.password")
      else
      flash[:error]  = t("controllers.update.error.password") + "<br />" + response.body
      end
      session[:user_admin] = nil
      session[:user_pass] = nil
      redirect_to edit_useradmin_profile_path(params[:id])
    else
    content_json =  {"uid" => params[:ippbx][:uid], "userTbl" => {"uid" => session[:user_admin_id],"alias" => params[:edit_profile][:alias]},
    "middleName" => params[:edit_profile][:middleName],"lastName" => params[:edit_profile][:lastName],
    "cellNumber" => params[:edit_profile][:cellNumber],
    "homePhone" => params[:edit_profile][:homePhone],"emailId" => params[:edit_profile][:emailId],
    "title" => params[:edit_profile][:title],"faxNumber" => params[:edit_profile][:faxNumber],
    "geographicDetails" => {"uid" => params[:geographicDetails][:uid],"timezone" => params[:edit_profile][:timezone],
    "locale" => params[:edit_profile][:locale],"zipCode" => params[:edit_profile][:zipCode],
    "state" => params[:edit_profile][:state],
    "language" => params[:edit_profile][:language],"addressLine2" => params[:edit_profile][:addressLine2],
    "addressLine1" => params[:edit_profile][:addressLine1],"country" => params[:edit_profile][:country],
    "city" => params[:edit_profile][:city]},"firstName" => params[:edit_profile][:firstName],
    "workPhone" => params[:edit_profile][:workPhone]}.to_json
    logger.info(content_json)
    response = IppbxApi.ippbx_put(session[:user_admin], session[:user_pass], 'user', 'profile', content_json)
    if response.code == '200'
    params_update_user = {:firstname => params[:edit_profile][:firstName],
    :lastname => params[:edit_profile][:lastName],
    :phone => params[:edit_profile][:workPhone],
    :cellphone => params[:edit_profile][:cellNumber],
    :email => params[:edit_profile][:emailId],
    :address  => params[:edit_profile][:addressLine1],
    :address2 => params[:edit_profile][:addressLine2],
    :zipcode => params[:edit_profile][:zipCode],
    :state => params[:edit_profile][:state],
    :country => params[:edit_profile][:country],
    :city => params[:edit_profile][:city]
    }  
    params_update_user[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
    Ippbx.update_ippbx_user params_update_user, session[:user_admin_id]
    flash[:notice]  = t("controllers.update.ok.user_profile")
    redirect_to :action => :index
    else
    flash[:error]  = t("controllers.update.error.user_profile") + "<br />" + response.body
    redirect_to :action => :edit
    end
    end
  end

  def edit
    response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'profile', nil)
    if response.code == '200'
    @profile = ActiveSupport::JSON.decode(response.body)
    @uid = @profile["uid"]
    @emailId = @profile["emailId"]
    @userTbl_uid = @profile["userTbl"]["uid"]
    @alias = @profile["userTbl"]["alias"]
    @featureSet = @profile["userTbl"]["featureSet"]
    @activeStatus = @profile["userTbl"]["activeStatus"]
    @featureStatus = @profile["userTbl"]["featureStatus"]
    @loginName = @profile["userTbl"]["loginName"]
    @middleName = @profile["middleName"]
    @lastName = @profile["lastName"]
    @workExtension = @profile["workExtension"]
    @cellNumber = @profile["cellNumber"]
    @homePhone = @profile["homePhone"]
    @title = @profile["title"]
    @faxNumber = @profile["faxNumber"]
    @firstName = @profile["firstName"]
    @workPhone = @profile["workPhone"]
    @geographicDetails_uid = @profile["geographicDetails"]["uid"]
    @timezone = @profile["geographicDetails"]["timezone"]
    @locale = @profile["geographicDetails"]["locale"]
    @zipCode = @profile["geographicDetails"]["zipCode"]
    @state = @profile["geographicDetails"]["state"]
    @language = @profile["geographicDetails"]["language"]
    @addressLine1 = @profile["geographicDetails"]["addressLine1"]
    @addressLine2 = @profile["geographicDetails"]["addressLine2"]
    @city = @profile["geographicDetails"]["city"]
    @country = @profile["geographicDetails"]["country"]
    else
    flash[:error]  = t("controllers.get.error.user_profile") + "<br />" + response.body
    end
  end

  def change_password
    # response = IppbxApi.ippbx_get(session[:user_admin], session[:user_pass], 'user', 'profile', nil)
    # @profile = ActiveSupport::JSON.decode(response.body)
    # @emailId = @profile["emailId"]
    # @userTbl_uid = @profile["userTbl"]["uid"]
    render :partial=>"change_password"
  end

end
