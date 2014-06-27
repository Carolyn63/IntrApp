class Entadmin::UsersController  < Entadmin::ResourcesController
  def create
    $public_numbers = nil
    action = params[:commit].downcase
    #emp_id, for creating a ippbx table tuple
    empid = params[:empid].to_s
    @form = params[:form].to_i
    case action
    when "cancel"
      @form = nil
      redirect_to  entadmin_users_path
      session[:user_details]=nil
    else
    if @form == 1
    
    session[:user_details]={
    :empid => empid,
    :firstname=>params[:user][:firstName],
    :lastname=> params[:user][:lastName],
    :email=> params[:user][:emailId],
    :phone=> params[:user][:homePhone],
    :cellphone=> params[:user][:cellNumber],
    :addressline1=> params[:user][:addressLine1],
    :addressline2=> params[:user][:addressLine2],
    :city=> params[:user][:city],
    :state=> params[:user][:state],
    :country=> params[:user][:country],
    :workphone => params[:user][:workPhone],
    :workextension => params[:user][:workExtension],
    :title => params[:user][:title],
    # :alias => params[:user][:alias],
    :fax=> params[:user][:faxNumber],
    :login=>params[:user][:loginName],
    :timezone=>params[:user][:timezone],
    :zipcode => params[:user][:zipCode],
    :locale=> params[:user][:locale],
    :language=> params[:user][:language]
    }
    employee = Employee.find(params[:empid])
    user = User.find(employee.user_id)
    user_password = Tools::AESCrypt.new.decrypt(user.user_password)
    content_json = {"password" => user_password,"featureSet" => params[:user][:featureSet],
    "activeStatus" => params[:user][:activeStatus] == "1" ? true : false,
    "alias" => params[:user][:alias],"loginName" => params[:user][:loginName],
    "enterpriseContacts" => [{"firstName" => params[:user][:firstName],
    "lastName" => params[:user][:lastName],"title" => params[:user][:title],
    "workPhone" => params[:user][:workPhone],"emailId" => params[:user][:emailId],
    "workExtension" => params[:user][:workExtension],"homePhone" => params[:user][:homePhone],
    "cellNumber" => params[:user][:cellNumber],"faxNumber" => params[:user][:faxNumber],
    "geographicDetails" => {"timezone" => params[:user][:timezone],"zipCode" => params[:user][:zipCode],
    "locale" => params[:user][:locale],"state" => params[:user][:state],
    "language" => params[:user][:language],"addressLine2" => params[:user][:addressLine2],
    "addressLine1" => params[:user][:addressLine1],"city" => params[:user][:city],
    "country" => params[:user][:country]}}]}.to_json
    response = IppbxApi.ippbx_post(session[:ent_admin], session[:ent_pass], 'ent', 'user', content_json)
    if response.code == '200'
    #this id needs to be optimised
    session[:ippbx_user_id] = ActiveSupport::JSON.decode(response.body)["uid"]
    logger.info "------==========----------============#{session[:ippbx_user_id]}"
    encrypt_password = Tools::AESCrypt.new.encrypt(user_password)
    date_time =Time.new.strftime("%Y-%m-%d %H:%M:%S")
    public_number = Ippbx.retrieve_public_number session[:portal_ent_id]
    params_fields = {:uid =>session[:ippbx_user_id], :admin_type => "user", :name =>params[:user][:firstName]+" "+ params[:user][:lastName], :login=>params[:user][:loginName], :password => encrypt_password, :company_id=> session[:portal_ent_id], :employee_id=>params[:empid], :public_number=>public_number, :mobile_number=>params[:user][:cellNumber], :extension=>params[:user][:workExtension], :date_created => date_time}
    Ippbx.create_ippbx params_fields

    IppbxNotifier.deliver_welcome_user_admin(params[:user][:loginName],user_password, params[:user][:emailId]) unless params[:user][:emailId].blank?
    IppbxNotifier.deliver_welcome_user_admin(params[:user][:loginName],user_password, employee.company_email)
    flash[:notice]  = t("controllers.create.ok.user_profile")
    session[:employee_id]=params[:empid]
    session[:user_details]=nil

    else
    @form -= 1
    flash[:error]  = t("controllers.create.error.user_profile") + "<br />" + response.body
    end
    #Form 2
    elsif @form == 2
    if session[:ippbx_user_id].blank?
    @form = 0
    else
    features = Array.new(params[:row][:count].to_i)
    for i in 0..(params[:row][:count].to_i - 1)
    features[i] = "{\"featureCode\":\""+params[:featureCode][i.to_s]+"\",\"assigned\":"+ params[:assign][i.to_s].to_s + "}"
    end
    features_str = features.to_sentence(:skip_last_comma => true, :connector => ", ")
    content_json ="{\"userTbl\":{\"uid\":" + session[:ippbx_user_id] + "},\"features\":[" + features_str + "]}"
    logger.info "Posting Json Data, @form 2: #{content_json}"
    response = IppbxApi.ippbx_put(session[:ent_admin], session[:ent_pass], 'ent', 'userfeatures', content_json)
    if response.code == '200'
    flash[:notice]  = t("controllers.assign.ok.features")
    else
    @form -= 1
    flash[:error]  = t("controllers.assign.error.features") + "<br />" + response.body
    end
    end
    #Form 3
    elsif @form == 3
    if session[:ippbx_user_id].blank?
    @form = 0  #return to create user page
    else

    begin
    @new_number = params[:assign][:pnumber]
    rescue
    @new_number = ""
    end

    unless @new_number.blank?
    response = IppbxApi.ippbx_put(session[:ent_admin], session[:ent_pass], 'ent', 'publicnumber/assign/'+ @new_number + '/user/' + session[:ippbx_user_id].to_s, nil)
    if response.code == '200'

    flash[:notice]  = t("controllers.update.ok.assigned_public_numbers")
    session[:employee_id] = nil
    else
    @form -= 1
    flash[:error]  = t("controllers.update.error.assigned_public_numbers") + "<br />" + response.body
    end
    end
    end
    end

    if action == "next"
    @form += 1
    redirect_to  new_entadmin_user_path(:form => @form)
    elsif action == "finish"
    @form = nil
    session[:ippbx_user_id] = nil
    redirect_to  entadmin_users_path
    end

    end
  end

  def new
    @for_update = false
    @form = params[:form].to_i
    @form ||= 1
    @which_form = "form" + @form.to_s
    if @form == 1
      if params[:firstname]!=nil
      session[:user_details]=nil
      @empid = params[:empid]
      @firstName=  CGI::unescape(params[:firstname])
      @lastName =   CGI::unescape(params[:lastname])
      @loginName =  CGI::unescape(params[:loginName])
      @country= CGI::unescape(params[:country])
      @emailId=  CGI::unescape(params[:email])
      @workPhone=  CGI::unescape(params[:phone])
      @cellNumber=CGI::unescape(params[:cellphone])
      @addressLine1=  CGI::unescape(params[:address])
      @addressLine2=  CGI::unescape(params[:address2])
      @city= CGI::unescape(params[:city])
      @state= CGI::unescape(params[:state])
      @country = CGI::unescape(params[:country])
      logger.info(CGI::unescape(params[:city]))
      logger.info(@city)
      elsif session[:user_details]!=nil
      logger.info("values from Session................")
      logger.info(session[:user_details])
      @empid = session[:user_details][:empid]
      @firstName= session[:user_details][:firstname]
      @lastName =session[:user_details][:lastname]
      @country= session[:user_details][:country]
      @emailId= session[:user_details][:email]
      @homePhone=session[:user_details][:phone]
      @cellNumber=session[:user_details][:cellphone]
      @addressLine1=session[:user_details][:addressline1]
      @addressLine2=session[:user_details][:addressline2]
      @city=session[:user_details][:city]
      @state=session[:user_details][:state]
      @country =session[:user_details][:country]
      @workPhone=session[:user_details][:workphone]
      @title =session[:user_details][:title]
      # @alias=session[:user_details][:alias]
      @faxNumber=session[:user_details][:fax]
      @loginName=session[:user_details][:login]
      @timezone=session[:user_details][:timezone]
      @zipCode=session[:user_details][:zipcode]
      @locale=session[:user_details][:locale]
      @language=session[:user_details][:language]
      end

      resultsets = Ippbx.find_by_sql("select max(extension) as ext from ippbxes where company_id="+session[:portal_ent_id].to_s)

      unless resultsets[0].ext.blank?
      @workExtension=resultsets[0].ext.to_i+1
      else
      @workExtension=1001
      end

    elsif @form == 2
      response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'features/', 'all')
      if response.code == '200'
      @features = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.get.emtpy.assigned_features") if @features.blank?
      else
      flash[:error]  = t("controllers.get.error.assigned_features") + "<br />" + response.body
      end
    @features ||= ''
    elsif @form == 3
      if $public_numbers.blank?
        response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'publicnumber/', 'available')
        if response.code == '200'
        $public_numbers = ActiveSupport::JSON.decode(response.body)
        flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if $public_numbers.blank?
        else
        flash[:error]  = t("controllers.get.error.assigned_public_numbers") + "<br />" + response.body
        end
      end
    $public_numbers ||= Array.new
    @page_results = $public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
    end
  end

		def edit
			@for_update = true
			@form = params[:form].to_i
			@form ||= 1
			@which_form = "form" + @form.to_s
			@empid = params[:empid]
			@uid = params[:id]
			if @form == 1
				# #retrieve users
				response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass],'ent', 'user/', params[:id])
				if response.code == '200'
					@response_decode = ActiveSupport::JSON.decode(response.body)
          @title = @response_decode["title"]
          @alias = @response_decode["userTbl"]["alias"]
          @emailId = @response_decode["emailId"]
          @workPhone = @response_decode["workPhone"]
          @firstName = @response_decode["firstName"]
          @workExtension = @response_decode["workExtension"]
          @faxNumber = @response_decode["faxNumber"]
          @lastName = @response_decode["lastName"]
          @cellNumber = @response_decode["cellNumber"]
          @loginName = @response_decode["userTbl"]["loginName"]
          @homePhone = @response_decode["homePhone"]
					#@password = @response_decode["userTbl"]["password"]
					@password = ""
					@activeStatus = @response_decode["activeStatus"]
					@addressLine1 = @response_decode["geographicDetails"]["addressLine1"]
					@addressLine2 = @response_decode["geographicDetails"]["addressLine2"]
					@city = @response_decode["geographicDetails"]["city"]
					@state = @response_decode["geographicDetails"]["state"]
					@zipCode = @response_decode["geographicDetails"]["zipCode"]
					@locale = @response_decode["geographicDetails"]["locale"]
					@country = @response_decode["geographicDetails"]["country"]
					@language = @response_decode["geographicDetails"]["language"]
					@timezone = @response_decode["geographicDetails"]["timezone"]
					@geographic_details_uid = @response_decode["geographicDetails"]["uid"]
					@enterpriseContacts_uid = @response_decode["uid"]
				else
					flash[:error]  = t("controllers.get.error.user_profile") + "<br />" + response.body
				end

			elsif @form == 2
				response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'features/', 'all')
				if response.code == '200'
				@features = ActiveSupport::JSON.decode(response.body)
				flash.now[:warning]  = t("controllers.get.empty.assigned_features") if @features.blank?
				else
				flash[:error]  = t("controllers.get.error.assigned_features") + "<br />" + response.body
				end
			@features ||= ''
			elsif @form == 3
				if $public_numbers.blank?
					response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'publicnumber/', 'available')
					if response.code == '200'
					$public_numbers = ActiveSupport::JSON.decode(response.body)
					flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if $public_numbers.blank?
					else
					flash[:error]  = t("controllers.get.error.assigned_public_numbers") + "<br />" + response.body
					end
				end
			$public_numbers ||= Array.new
			#just return the first number, the whole code might need to be change, so, temperaly changed to: [0..0]
			@page_results = $public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
			end
		end

  def update
    $public_numbers = nil
    firstname = params[:firstname].to_s
    lastname = params[:lastname].to_s
    empid = params[:empid].to_s
    logger.info("empID........"+empid)
    action = params[:commit].downcase
    @form = params[:form].to_i
    case action
    when "cancel"
      @form = nil
      redirect_to  ippbx_entadmin_users_path
    else
    #Form 1
    if @form == 1
      
   content_json = {"uid" => params[:id].to_i, "password" => params[:user][:password],
    "activeStatus" => params[:user][:activeStatus] == "1" ? true : false,
    "alias" => params[:user][:alias],
    "enterpriseContacts" => [{"uid" => params[:enterpriseContacts][:uid].to_i, "firstName" => params[:user][:firstName],
    "lastName" => params[:user][:lastName],"title" => params[:user][:title],
    "workPhone" => params[:user][:workPhone],"emailId" => params[:user][:emailId],
    "workExtension" => params[:user][:workExtension],"homePhone" => params[:user][:homePhone],
    "cellNumber" => params[:user][:cellNumber],"faxNumber" => params[:user][:faxNumber],
    "geographicDetails" => {"uid" => params[:geographicDetails][:uid].to_i, "timezone" => params[:user][:timezone],"zipCode" => params[:user][:zipCode],
    "locale" => params[:user][:locale],"state" => params[:user][:state],
    "language" => params[:user][:language],"addressLine2" => params[:user][:addressLine2],
    "addressLine1" => params[:user][:addressLine1],"city" => params[:user][:city],
    "country" => params[:user][:country]}}]}.to_json

    logger.info "Putting Json Data, @form 1: #{content_json}"

    response = IppbxApi.ippbx_put(session[:ent_admin], session[:ent_pass], 'ent', 'user', content_json)

    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.user_profile")
    session[:employee_id]=empid
    params_update_user = {:firstname => params[:user][:firstName],
    :lastname => params[:user][:lastName],
    :cellphone => params[:user][:cellNumber],
    :phone => params[:user][:workPhone],
    :email => params[:user][:emailId],
    :address  => params[:user][:addressLine1],
    :address2 => params[:user][:addressLine2],
    :zipcode => params[:user][:zipCode],
    :state => params[:user][:state],
    :country => params[:user][:country],
    :city => params[:user][:city],
    :extension => params[:user][:workExtension]
    }  
    
    params_update_user[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
    Ippbx.update_ippbx_user params_update_user, params[:id]

    else
    @form -= 1 #remain in the same @form
    flash[:error]  = t("controllers.update.error.user_profile") + "<br />" + response.body
    end
    #Form 2
    elsif @form == 2
    features = Array.new(params[:row][:count].to_i)
    for i in 0..(params[:row][:count].to_i - 1)
    features[i] = "{\"featureCode\":\""+params[:featureCode][i.to_s]+"\",\"assigned\":"+ params[:assign][i.to_s].to_s + "}"
    end
    features_str = features.to_sentence(:skip_last_comma => true, :connector => ", ")
    content_json ="{\"userTbl\":{\"uid\":" + params[:id] + "},\"features\":[" + features_str + "]}"
    logger.info "Posting Json Data, @form 2: #{content_json}"
    response = IppbxApi.ippbx_put(session[:ent_admin], session[:ent_pass], 'ent', 'userfeatures', content_json)
    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.assigned_features")
    else
    @form -= 1 #remain in the same @form
    flash[:error]  = t("controllers.update.error.assigned_features") + "<br />" + response.body
    end
    elsif @form == 3
    begin
    @new_number = params[:assign][:pnumber]
    rescue
    @new_number = ""
    end

    begin
    @old_number = params[:assigned_public_number]
    rescue
    @old_number = ""
    end

    unless @new_number.blank?
    unless @old_number.blank?
    IppbxApi.ippbx_put(session[:ent_admin], session[:ent_pass], 'ent', 'publicnumber/unassign/'+ @old_number + '/user/' + params[:id].to_s, nil)
    end
    response = IppbxApi.ippbx_put(session[:ent_admin], session[:ent_pass], 'ent', 'publicnumber/assign/'+ @new_number + '/user/' + params[:id].to_s, nil)
    logger.info ":assigned_public_number: #{params[:assigned_public_number]}"
    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.assigned_public_numbers")
    session[:employee_id] = nil
    else
    @form -= 1
    flash[:error]  = t("controllers.update.error.assigned_public_numbers") + "<br />" + response.body
    end
    end
    end

    if action == "next"
    @form += 1
    redirect_to  edit_entadmin_user_path(params["id"], :form=>@form)
    elsif action == "finish"
    @form =nil
    redirect_to  ippbx_entadmin_users_path
    end
    end
  end

  def index
    @result=0
    emailId = addslash(params[:emailId]).strip
    firstName = addslash(params[:firstName]).strip
    lastName = addslash(params[:lastName]).strip
    #default sql
    sql_str = "select * from employees where company_id="+session[:portal_ent_id].to_s+" and status='active'"
    if !params[:firstName].blank? and !params[:lastName].blank? and !params[:emailId].blank?
    sql_str = "select * from employees e join users u on e.user_id = u.id where (u.email regexp '"+emailId+"' and u.firstname regexp '"+firstName+"' and u.lastname regexp '"+lastName+"') and e.company_id="+session[:portal_ent_id].to_s
    elsif !params[:firstName].blank? and !params[:lastName].blank?
    sql_str = "select * from employees e join users u on e.user_id = u.id where (u.firstname regexp '"+firstName+"' and u.lastname regexp '"+lastName+"') and e.company_id="+session[:portal_ent_id].to_s
    elsif !params[:firstName].blank?
    sql_str = "select * from employees e join users u on e.user_id = u.id where u.firstname regexp '"+firstName+"' and e.company_id="+session[:portal_ent_id].to_s
    elsif !params[:lastName].blank?
    sql_str = "select * from employees e join users u on e.user_id = u.id where u.lastname regexp '"+lastName+"' and e.company_id="+session[:portal_ent_id].to_s
    elsif !params[:emailId].blank?
    sql_str = "select * from employees e join users u on e.user_id = u.id where u.email regexp '"+emailId+"' and e.company_id="+session[:portal_ent_id].to_s
    end
    @employees = Employee.find_by_sql(sql_str).paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
    @result = @employees.count()
    flash.now[:warning] = t("controllers.search.empty") if @result==0
  end

  def ippbx
    if params[:commit] == 'Search'
      criteria = 'criteria={'
      criteria += 'firstName:'+ CGI::escape(params[:firstName].strip) + ';' unless params[:firstName].strip.blank?
      criteria += 'lastName:'+CGI::escape(params[:lastName].strip) + ';' unless params[:lastName].strip.blank?
      criteria += 'emailId:'+params[:emailId].strip + ';' unless params[:emailId].strip.blank?
      criteria += 'workPhone'+CGI::escape(params[:workPhone].strip) + ';' unless params[:workPhone].strip.blank?
      criteria += 'workExtension:'+CGI::escape(params[:workExtension].strip) + ';' unless params[:workExtension].strip.blank?
      criteria += 'activeStatus:'+CGI::escape(params[:activeStatus].strip) + ';' unless params[:activeStatus].strip.blank?
      criteria += '}'
      response = IppbxApi.ippbx_search(session[:ent_admin], session[:ent_pass],'ent', 'resource=User&orderBy=firstName&sortOrder=asc&', criteria)
      if response.code == '200'
      @users = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.search.empty") if @users.blank?
      else
      flash[:error]  = t("controllers.search.error.users_list") + "<br />" + response.body
      end
    else
      response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'user/', 'all')
      if response.code == '200'
      @users = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.get.empty.users_list") if @users.blank?
      else
      flash[:error]  = t("controllers.get.error.users_list") + "<br />" + response.body
      end
    end
    @users ||= ''
  end

  def destroy
    if !params[:id].blank?
      response = IppbxApi.ippbx_delete(session[:ent_admin], session[:ent_pass], 'ent', 'user/', params[:id])
      if response.code == '200'
      ippbx = Ippbx.find_by_admin_type_and_uid("user",params[:id])
      employee = Employee.find(ippbx.employee_id)
      Ippbx.destroy_employee_ippbx_by_ippbx_uid(params[:id])
      flash[:notice]  = t("controllers.delete.ok.user")
      IppbxNotifier.deliver_user_admin_delete(params[:loginName], params[:emailId]) unless params[:emailId].blank?
      
      IppbxNotifier.deliver_user_admin_delete(params[:loginName], employee.company_email)
      else
      flash[:error]  = t("controllers.delete.error.user") + "<br />" + response.body
      end
    end
    redirect_to  ippbx_entadmin_users_path
  end

end
