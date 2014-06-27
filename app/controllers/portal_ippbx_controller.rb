class PortalIppbxController < ApplicationController

	def vm_get_all(uid)
	@user_cred = Ippbx.find_by_admin_type_and_uid("user",uid.to_s)
	domain = Company.find_by_id(@user_cred.company_id.to_s).domain_name;
	user_login = @user_cred.login.to_s + '@' + domain.to_s
	user_password = Tools::AESCrypt.new.decrypt(@user_cred.password)

		response = IppbxApi.ippbx_get(user_login, user_password, 'vm', '/voicemailrecord/', 'all')
		if response.code == '200'
			return ActiveSupport::JSON.decode(response.body)      
		end
		return Array.new
	end
	
	
	def vm_get_new(uid)
	@user_cred = Ippbx.find_by_admin_type_and_uid("user",uid.to_s)
	domain = Company.find_by_id(@user_cred.company_id.to_s).domain_name;
	user_login = @user_cred.login.to_s + '@' + domain.to_s
	user_password = Tools::AESCrypt.new.decrypt(@user_cred.password)

		response = IppbxApi.ippbx_get(user_login, user_password, 'vm', '/voicemailrecord/', 'new')
		if response.code == '200'
			return ActiveSupport::JSON.decode(response.body)      
		end
		return Array.new
	end
  
	def vm_get_seen(uid)
	@user_cred = Ippbx.find_by_admin_type_and_uid("user",uid.to_s)
	domain = Company.find_by_id(@user_cred.company_id.to_s).domain_name;
	user_login = @user_cred.login.to_s + '@' + domain.to_s
	user_password = Tools::AESCrypt.new.decrypt(@user_cred.password)

		response = IppbxApi.ippbx_get(user_login, user_password, 'vm', '/voicemailrecord/', 'saved')
		if response.code == '200'
			return ActiveSupport::JSON.decode(response.body)      
		end
		return Array.new
	end


def vm_get_one(uid, vm_id)
	@user_cred = Ippbx.find_by_admin_type_and_uid("user",uid.to_s)
	domain = Company.find_by_id(@user_cred.company_id.to_s).domain_name;
	user_login = @user_cred.login.to_s + '@' + domain.to_s
	user_password = Tools::AESCrypt.new.decrypt(@user_cred.password)

		vm_id = params[:vm_id]
		response = IppbxApi.ippbx_get(user_login, user_password, 'vm', '/voicemailrecord/', vm_id)
		if response.code == '200'
			return ActiveSupport::JSON.decode(response.body)      
		end
		return Array.new
	end
	
	
	def vm_delete_one(uid, vm_filter, vm_id)
	@user_cred = Ippbx.find_by_admin_type_and_uid("user",uid.to_s)
	domain = Company.find_by_id(@user_cred.company_id.to_s).domain_name;
	user_login = @user_cred.login.to_s + '@' + domain.to_s
	user_password = Tools::AESCrypt.new.decrypt(@user_cred.password)

		#vm_id = params[:vm_id]
		#vm_filter = params[:vm_filter]
		response = IppbxApi.ippbx_delete(user_login, user_password, 'vm', '/voicemailrecord/', vm_id)
		if response.code == '200'
			next_response = IppbxApi.ippbx_get(user_login, user_password, 'vm', '/voicemailrecord/', vm_filter)
			if next_response.code == '200'
				return ActiveSupport::JSON.decode(next_response.body)
			end
		end
		return Array.new
	end
	
	
	def vm_set_seen(uid, vm_filter, vm_id)
	@user_cred = Ippbx.find_by_admin_type_and_uid("user",uid.to_s)
	domain = Company.find_by_id(@user_cred.company_id.to_s).domain_name;
	user_login = @user_cred.login.to_s + '@' + domain.to_s
	user_password = Tools::AESCrypt.new.decrypt(@user_cred.password)

		json_content = {"uid"=>vm_id,"status"=>true}.to_json 
		response = IppbxApi.ippbx_put(user_login, user_password, 'vm', '/voicemailrecord', json_content)
		if response.code == '200'
			next_response = IppbxApi.ippbx_get(user_login, user_password, 'vm', '/voicemailrecord/', vm_filter)
			if next_response.code == '200'
				return ActiveSupport::JSON.decode(next_response.body)
			end
		else
			#error message
			#return "error"
			return Array.new
		end
	end


  def destroy_ippbx_user(param, company_id)
    @entcred = Ippbx.find_by_admin_type_and_company_id("enterprise", company_id.to_s)
    ent_username = @entcred.login
    ent_password = Tools::AESCrypt.new.decrypt(@entcred.password)
    count = param.count
    for i in (0..count-1)
      employee = Ippbx.find_by_employee_id(param[i])
      unless employee.blank?
        response = IppbxApi.ippbx_delete(ent_username, ent_password, 'ent', 'user/', employee.uid.to_s)
        if response.code == '200'
          #Ippbx.delete_all "employee_id = '" + param[i].to_s + "'"
          else
          flash[:error] = t("controllers.employees_delete_failed")
          redirect_to company_employees_path(company_id)
        end
      end

    end
  end

  def destroy_ippbx_enterprise(company_id)
    @spcred = Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
    sp_username = @spcred.login
    sp_password  = Tools::AESCrypt.new.decrypt(@spcred.password)
    logger.info("spusername*****************************#{sp_username}")
    @ent = Ippbx.find_by_admin_type_and_company_id("enterprise", company_id.to_s)
    #@ent = Ippbx.find_by_sql("SELECT uid FROM ippbxes WHERE admin_type='enterprise' and company_id='" +addslash(company_id.to_s)+ "'")
    delete_response = IppbxApi.ippbx_delete(sp_username, sp_password.to_s, 'sp', 'enterprise/', @ent.uid.to_s)
    if delete_response.code == '200'
      Ippbx.delete_all "company_id = '" + company_id.to_s + "'"
      Domain.delete_all "company_id = '" + company_id.to_s + "'"
    return true
    else
      logger.info("delete Response#{delete_response.body}")
      flash[:error]=t("controllers.failed_delete_company")
      redirect_to company_path(company_id)
    end
  end

  def edit_ippbx_employee(param_fields, user)
    employee = Employee.find_by_user_id(user.id)
    ippbx_uid=employee.ippbx.uid
    @ent_cred = Ippbx.find_by_admin_type_and_uid("user",ippbx_uid)
    user_login = @ent_cred.login
    user_password = Tools::AESCrypt.new.decrypt(@ent_cred.password)
    response = IppbxApi.ippbx_get(user_login, user_password,'user', 'profile', nil)
    param_fields[:employee_id] = employee.id
    if response.code == '200'
      unless param_fields[:sex].blank?
        param_fields[:sex] == "Male" ? user_title = "Mr" : user_title ="Ms"
      end
      @profile = ActiveSupport::JSON.decode(response.body)
      @geographicDetails_uid = @profile["geographicDetails"]["uid"]
      usertb_id = @profile["userTbl"]["uid"]
      uid = @profile["uid"]
      content_json = {"uid" => uid,"userTbl" => {"uid" => ippbx_uid},
        "firstName" =>  param_fields[:firstname],
        "lastName" => param_fields[:lastname],
        "title" => user_title,
        "workPhone" => param_fields[:phone],
        "cellNumber" => param_fields[:cellphone],
        "emailId" =>param_fields[:email],
        "geographicDetails" => {"uid" => @geographicDetails_uid,
          "zipCode" => param_fields[:zipcode],
          "state" => param_fields[:state],
          "addressLine2" => param_fields[:address2],
          "addressLine1" => param_fields[:address],"country" => param_fields[:country],
          "city" =>  param_fields[:city]}
      }.to_json
      update_response = IppbxApi.ippbx_put(user_login,user_password, 'user','profile', content_json)
      if update_response.code == '200'
        simultaneous_ring_number = ""
        #simultaneous_ring_number+= param_fields[:phone] + "," unless param_fields[:phone].blank?
        #simultaneous_ring_number+= param_fields[:cellphone]+ "," unless param_fields[:cellphone].blank?
        simultaneous_ring_number+= param_fields[:cellphone] unless param_fields[:cellphone].blank?
        #simultaneous_ring_number+= param_fields[:cellphone] unless param_fields[:cellphone].blank? # remove when ext in fixed. use above and below
        #simultaneous_ring_number+= employee.ippbx.extension.to_s
        simr_array = simultaneous_ring_number.split(",")
        if simr_array.size > 0
          content_json =  {"featureCode" => "SIMR", "active" => true,  "featureRecord" => {"number" => simultaneous_ring_number, "treatment" => "User is Busy"}}.to_json
          response = IppbxApi.ippbx_put(user_login, user_password, 'user', 'feature/record', content_json)
          if response.code == "200"
            parms_update = {:mobile_number => param_fields[:cellphone], :name => param_fields[:firstname] + " " + param_fields[:lastname] }
            parms_update[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
            Ippbx.update_employee_ippbx parms_update, employee.id
          return true
          else
          return false
          end
        else
          content_json =  {"featureCode" => "SIMR", "active" => false}.to_json
          response = IppbxApi.ippbx_put(user_login, user_password, 'user', 'feature/record', content_json)
          if response.code == "200"
            parms_update = {:mobile_number => param_fields[:cellphone], :name => param_fields[:firstname] + " " + param_fields[:lastname] }
            parms_update[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
            Ippbx.update_employee_ippbx parms_update, employee.id
          return true
          else
          return false
          end
        end
      return true
      else
      return false
      end
    else
    return false
    end
  end

  def edit_ippbx_enterprise(param_fields, company)
    @ent_cred = Ippbx.find_by_admin_type_and_company_id("enterprise",company.id.to_s)
    ent_login = @ent_cred.login
    ent_password = Tools::AESCrypt.new.decrypt(@ent_cred.password)
    logger.info("username>>>>>>>>>>>>>>>>>>>>>>#{ent_login}")
    logger.info("username>>>>>>>>>>>>>>>>>>>>>>#{ent_password}")
    response = IppbxApi.ippbx_get(ent_login, ent_password,'ent', 'profile', nil)
    if response.code =='200'
      @profile = ActiveSupport::JSON.decode(response.body)
      @geographic_details_uid = @profile["enterprise"]["geographicDetails"]["uid"]
      content_json = {"enterprise" =>{"uid" => @ent_cred.uid,
          "name" => param_fields[:name],
          #"activeStatus" => "true",
          "geographicDetails" => {"uid" => @geographic_details_uid,
            "zipCode" => param_fields[:zipcode],
            "state" => param_fields[:state],
            "addressLine2" => param_fields[:address],
            "addressLine1" => param_fields[:address2],
            "city" => param_fields[:city],
            "country" => param_fields[:country]},
          "url" => param_fields[:website]
        }}.to_json
      logger.info(content_json)
      update_response = IppbxApi.ippbx_put(ent_login, ent_password,'ent', 'profile', content_json)
      if update_response.code == '200'
        parms_update = {:name => param_fields[:name]}
        parms_update[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
        parms_update = remove_space(parms_update)
        logger.info("Updating.......................")
        Ippbx.update_enterprise_ippbx parms_update, company.id
        logger.info("Updated...........................")
        unless param_fields[:domain_name].blank?
          params_domain={:company_id=>company.id, :name=>param_fields[:domain_name]}
          Domain.update_domain params_domain
        end
      return true
      else
      return false
      end
    end
  end

  def fda
    #http://<host:port>/provisioning/voip/v1/user/callcontrol/voicemailrecord/all
  end

  def user_has_ippbx user
    unless user.employees[0].blank?
    return true unless user.employees[0].ippbx.blank?
    end
  end

  def sp_has_vm (sp_username,sp_password)
    response = IppbxApi.ippbx_get(sp_username, sp_password, 'sp', 'features/', 'all')
    if response.code == '200'
      @sp_features = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.get.empty.assigned_features") if @sp_features.blank?
      @sp_features.each do |feature|
        logger.info(feature)
        logger.info("checking Features---------------------")
        if feature["featureCode"] == "VM"
          logger.info("true")
          @show_vm = true
        end
      end
    end
  end
  
   def add_company_ippbx (company_id, employees_count)
     success = false
    #@spcred = Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
    @spcred = Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
    sp_username = @spcred.login
    sp_password  = Tools::AESCrypt.new.decrypt(@spcred.password)
    #company_id=params[:id]
    company = Company.find(company_id)
    current_user = User.find_by_id(company.user_id)
    # Domain Creation
    if company.domain_name.blank?
      #domain_name = company.name.gsub(" ","")
      #domain_name = company.name.gsub(/[^0-9a-z]/i, '') + "."+ property(:domain)
      domain_name = company.name.gsub(/[^0-9a-z]/i, '')
    else
      domain_name = company.domain_name
    end
		domain_name = domain_name[0,19] # added by jhlee on 20120611
    logger.info("comnpany domainname#{domain_name}")
    doamin_content_json = {"name" => domain_name.downcase}.to_json
    domain_response = IppbxApi.ippbx_post(sp_username, sp_password, 'sp', 'domain', doamin_content_json)
       if domain_response.code == '200'
      @domain_id = ActiveSupport::JSON.decode(domain_response.body)
      logger.info("Domains created....*************......#{@domain_id}")
      #Create default routing plan for company
      rdpgs_name = "RDPGS "+company.name.gsub(" ","").downcase
      rdpgs_name = rdpgs_name+company.id.to_s
      rdpgs_description = "Routing Dial Plan Groups for "+company.name
      rdpgs_content_json = {"name" => rdpgs_name,"description" => rdpgs_description, "routingXml" => ""}.to_json
      rdpgs_response = IppbxApi.ippbx_post(sp_username, sp_password, 'sp', 'routingdialplangroup',  rdpgs_content_json)
      if rdpgs_response.code == '200'
        @rdpgs_id=ActiveSupport::JSON.decode(rdpgs_response.body)
        logger.info("RDPGS Created....#{@rdpgs_id}")
        ## Getting first two public numbers to assign MN and VM
        response = IppbxApi.ippbx_get(sp_username, sp_password, 'sp', 'publicnumber/', 'available')
        if response.code == '200'
        $public_number = ActiveSupport::JSON.decode(response.body)

        $public_number ||= Array.new
        @MN = $public_number[0]["number"] if $public_number.size>0
        @VM = $public_number[1]["number"] if $public_number.size>1
        logger.info("public_number size #{$public_number.size.to_s}")
        end 

        #Create IP PBX Enterprise for company
				company_name = company.name
        content_json ={"enterprise" => {"geographicDetails" => {"timezone" => property(:default_timezone), "zipCode" => company.zipcode,
        "locale" =>property(:default_locale),"state" => company.state,
        "language" => property(:default_language),"addressLine2" => company.address2,
        "addressLine1" => company.address,"city" => company.city,
        "country" => company.country},
				"name" => company_name[0,19], # STUPID IPPBX ONLY ALLOW 20 CHARS
        "emailId" => current_user.email,
        "faxNumber" =>"","url" => company.website,
        "featureSet" => "all", "extensionLength" => "4",
        "activeStatus" => "true",
				"domains" => [{"uid" =>@domain_id["uid"]}],
        "routingDialPlanGroups" => [{"uid" => @rdpgs_id["uid"]}]},
        "enterprisePhoneNumberMaps" =>[{"type" => "MN","publicNumber" =>{"number" => @MN}}]}
        
        ## Checking sp is enbled VM features. If it is add VM related data in Json parameters.
        if sp_has_vm(sp_username,sp_password)
        content_json["enterprisePhoneNumberMaps"] << {"type" => "VM","publicNumber" =>{"number" => @VM},
                                                      "extension" => "1000"}
        content_json["enterprise"]["voiceMailBoxMaxLimit"] = "20"
  $vm = true
  else
  $vm = false
        end  
        content_json = content_json.to_json
        
        logger.info "Posting Json Data--: #{content_json}"
        response = IppbxApi.ippbx_post(sp_username, sp_password, 'sp', 'enterprise', content_json)
        logger.info("response #{response.code}")
        if response.code == '200'
          logger.info("Enterprise Created.**********************************&^^%%#{response.body}")
          @ent=ActiveSupport::JSON.decode(response.body)
          ent_username = company.name.gsub(/[\W]/i, "")
          ent_username = ent_username.slice(0,6)+company.id.to_s
          ent_username = ent_username.downcase
          ent_password = generate_password(8)
          #Create Admin for IP PBX Admin
          unless current_user.country.blank?
            user_country = current_user.country
          else
            user_country =property(:default_country)
          end
         
          admin_content_json = {"emailHost" => property(:email_host),"emailPort" => property(:email_port),
          "emailPassword" =>property(:email_password), "emailId" => current_user.email,"entityId" =>@ent["uid"],"geographicDetails" => {"timezone" => property(:default_timezone),
          "zipCode" => current_user.zipcode, "locale" =>property(:default_locale),"state" => current_user.state,
          "language" => property(:default_language), "addressLine2" =>current_user.address2,
          "addressLine1" => current_user.address,"city" => current_user.city,"country" => user_country},
          "type" => 3, "password" =>ent_password,"loginName" =>ent_username}.to_json
          admin_response = IppbxApi.ippbx_post(sp_username, sp_password, 'sp', 'enterpriseadmin', admin_content_json)
          if admin_response.code=='200'
            @admin_details = ActiveSupport::JSON.decode(admin_response.body)
            encrypt_password = Tools::AESCrypt.new.encrypt(ent_password)
            time = Time.new
            date_time = time.strftime("%Y-%m-%d %H:%M:%S")
            email_password = Tools::AESCrypt.new.encrypt(property(:email_password)) 
      params_fields = {:uid =>@ent["uid"], :admin_type => "enterprise", :name =>company.name, :login=>ent_username, :password => encrypt_password, :company_id=> company.id.to_s,:date_created => date_time, :public_number => @MN,
                       :email_host =>property(:email_host),:email_port => property(:email_port), :email_password => email_password}
            if $vm
      params_fields[:vm_number] = @VM
      end  
      logger.info("domain Uid >>>>>>>>>>>>>>>>>>>>>>>>>#{@domain_id}")
            params_domain = {:uid => @domain_id["uid"], :name =>domain_name.downcase, :company_id => company.id}
            Domain.create_domain params_domain
            Ippbx.create_ippbx params_fields
	    begin
            IppbxNotifier.deliver_welcome_ent_admin(ent_username, ent_password, current_user.email)
            IppbxNotifier.deliver_welcome_ent_admin(ent_username, ent_password, current_user.employees[0].company_email)
	    rescue
	    end
          else
          logger.info("Admin Failed$$$$$$$$$$$#{admin_response.body}")
          #flash[:error]=t("controllers.create.error.contact_spadmin")
          #redirect_to company_path(company_id)
          end
          # Assign Features.....t
          features_str = "{\"featureCode\":\"all\",\"assigned\":true}"
          features_content_json ="{\"enterprise\":{\"uid\":" + @ent["uid"] + "},\"features\":[" + features_str + "]}"
          logger.info("Posting Json features #{features_content_json}")
          features_response = IppbxApi.ippbx_put(sp_username,sp_password, 'sp', 'enterprisefeatures', features_content_json)
          if features_response.code=='200'
            logger.info("Feature assigned for Company")
          else
            #flash[:error]=t("controllers.create.error.contact_spadmin")
            #redirect_to company_path(company_id)
          end
          #Assign Public Number
          if !$public_number.blank? and $public_number.size > employees_count+3
          @numbers = ""
          for i in 2..(employees_count+1) # assign 5 public numbers for Enterprise 
            response = IppbxApi.ippbx_put(sp_username,sp_password, 'sp', 'publicnumber/assign/'+ $public_number[i]["number"].to_s + '/enterprise/' + @ent["uid"], nil)
            if response.code != '200'
              do_fail =true
              #flash[:error]=t("controllers.create.error.public_numbers") + " " + t("controllers.create.error.contact_spadmin") and redirect_to company_path(company_id)
            end
            #@numbers += $public_number[i]["number"] + ","
         end #for
   #Updat only MN not all public_numbers
         #@numbers = @numbers.chop
         #params_update = {:public_number =>@numbers}
         #logger.info("parameters for update #{params_update}")
         #Ippbx.update_enterprise_ippbx params_update, company.id
         #flash[:notice] = t("controllers.create.ok.enable_ippbx") and redirect_to company_path(company_id) unless do_fail
	 success = true unless do_fail
         end

        else
        delete_rdpg_response = IppbxApi.ippbx_delete(sp_username,sp_password, 'sp', 'routingdialplangroup/', @rdpgs_id["uid"])
        delete_domain_response = IppbxApi.ippbx_delete(sp_username,sp_password, 'sp', 'domain/', @domain_id["uid"])
        if delete_domain_response.response =='200'
        Domain.destroy_domain(company_id)
        end
        #redirect_to company_path(company_id)
        logger.info("response body#{response.body}")
        #flash[:error]=t("controllers.create.error.contact_spadmin")
        end
      else
        #flash[:error]=t("controllers.create.error.contact_spadmin")
        #redirect_to company_path(company_id)
      end
    else
      #flash[:error]=t("controllers.create.error.contact_spadmin")
      #logger.info("RDPGS body#{rdpgs_response.body}")
      #redirect_to company_path(company_id)
    end
  #=end
  #redirect_to company_path(params[:id])
    return success
  end

def add_user_ippbx user_id, use_public_number
   unless user_id.blank?
      @user = User.find(user_id)
      extension=''
      user_login = @user.login
      user_password = Tools::AESCrypt.new.decrypt(@user.user_password)
      company_resultset = @user.employees[0].company
      #company_name =current_user.employees[0].company.name
      #company_id =current_user.employees[0].company.id
      company_name = company_resultset.name
      company_domain = company_resultset.domain.name
      company_id = company_resultset.id
      @entcred = Ippbx.find_by_admin_type_and_company_id("enterprise", company_id.to_s)
      ent_username = @entcred.login
      ent_password = Tools::AESCrypt.new.decrypt(@entcred.password)
      #@entcred = Ippbx.find_by_sql("SELECT *,AES_DECRYPT(password, '"+property(:cryptpass)+"') as pwd FROM ippbxes WHERE admin_type='enterprise' and company_id='" + addslash(company_id.to_s) + "'")
      logger.info("Ent Cred*******************#{ent_username}")
      logger.info("Ent Cred*******************#{ent_password}")
      #retrieve public numbers
      available_response = IppbxApi.ippbx_get(ent_username, ent_password, 'ent', 'publicnumber/', 'available')
      if available_response.code == '200'
      @public_numbers = ActiveSupport::JSON.decode(available_response.body)
      @public_numbers ||= Array.new
      workphone =  ""
      if @public_numbers.size>0 or !use_public_number
        #if params[:enable_pn] == "1"
	     
             workphone = @public_numbers[0]["number"] if use_public_number
	     
        #end    
       resultsets = Employee.find_by_sql("select max(extension) as ext from ippbxes where company_id='"+@user.employees[0].company.id.to_s+"'")
      unless resultsets[0].ext.blank?
      extension=resultsets[0].ext
      else
      extension='1000'
      end
      extension = extension.to_i+10
      logger.info("extension****************#{extension}")
      unless @user.country.blank?
      user_country = @user.country
      else
      user_country =property(:default_country)
      end
      user_title=""
      unless @user.sex.blank?
      @user.sex == "Male" ? user_title = "Mr" : user_title ="Ms"
      end
      #Step1 User Creation # "featureSet" => "all" to "featureSet" => "11111111111110" because AA cannot be atuo assigned
      content_json = {"password" => user_password,"featureSet" => "all",
        "activeStatus" => "true",
        "alias" => "","loginName" => user_login,
        "enterpriseContacts" => [{"firstName" => @user.firstname,
            "lastName" => @user.lastname,"title" => user_title,
            "workPhone" => workphone,"emailId" =>@user.email,
            "workExtension" => extension.to_s,"homePhone" => "",
            "cellNumber" => @user.cellphone,"faxNumber" => "",
            "geographicDetails" => {"timezone" => property(:default_timezone),"zipCode" =>@user.zipcode,
              "locale" =>property(:default_locale),"state" => @user.state,
              "language" => property(:default_language),"addressLine2" => @user.address2,
              "addressLine1" => @user.address,"city" => @user.city,
              "country" => user_country }}]}.to_json
      logger.info "Posting Json Data, @form 1: #{content_json}"
      response = IppbxApi.ippbx_post(ent_username, ent_password, 'ent', 'user', content_json)
      if response.code == '200'
        logger.info("user Created")
        user_id= ActiveSupport::JSON.decode(response.body)["uid"]
        available_response = IppbxApi.ippbx_get(ent_username, ent_password, 'ent', 'user/', user_id)
        @ippbx_user_id= ActiveSupport::JSON.decode(response.body)["uid"]
        logger.info("REsponse UID>>>>>>>>>>>>>>>>>>>>>>>>>>>#{@ippbx_user_id}")
        #Employee.update_all("is_ippbx_enabled=1, ippbx_id='"+@ippbx_user_id+"', extension='"+extension.to_s+"' ", "user_id='"+current_user.id.to_s+"'")
        encrypt_password = Tools::AESCrypt.new.encrypt(user_password)
        time = Time.new
        date_time =time.strftime("%Y-%m-%d %H:%M:%S")
        User.update(@user.id,{:phone => workphone})
        params_create = {:uid =>@ippbx_user_id, :admin_type => "user", :name =>@user.firstname+ " " + @user.lastname, :login=>user_login + "@" + company_domain, :password => encrypt_password, :company_id=> company_id.to_s, :employee_id => @user.employees[0].id.to_s,:extension=> extension.to_s, :mobile_number => @user.cellphone,:date_created => date_time}
        Ippbx.create_ippbx params_create
        #ActiveRecord::Base.connection.execute("INSERT INTO ippbxes (uid, admin_type, name, login, password, company_id,employee_id,date_created) VALUES ('"+addslash(@ippbx_user_id)+"','user','"+addslash(current_user.firstname+ " " + current_user.lastname)+"','"+addslash(user_login)+"',AES_ENCRYPT('"+user_password+"', '"+property(:cryptpass)+"'),'"+addslash(company_id.to_s)+"','"+addslash(current_user.employees[0].id.to_s)+"',NOW())")
        begin
	IppbxNotifier.deliver_welcome_user_admin(user_login + "@" + company_domain, user_password, @user.email)
        IppbxNotifier.deliver_welcome_user_admin(user_login + "@" + company_domain, user_password, @user.employees[0].company_email)
	rescue
	end
	feature_content_json ="{\"userTbl\":{\"uid\":" + @ippbx_user_id + "},\"features\":[{\"featureCode\":\"all\",\"assigned\":true}]}"
        logger.info "Posting Json Data, @form 2: #{feature_content_json}"
        feature_response = IppbxApi.ippbx_put(ent_username, ent_password, 'ent', 'userfeatures', feature_content_json)
        if feature_response.code == '200'
        #flash[:notice] = t("controllers.create.ok.enable_ippbx")
        #redirect_to user_path(@user.id)
        logger.info("all Features Assigned")
        else
        logger.info("User Creation Failed#{feature_response.body}")
        #redirect_to user_path(@user.id)
        #flash[:error] = t("controllers.create.error.features") + t("controllers.create.error.contact_entadmin")
        end
        #assign public Number
        if use_public_number
        if @public_numbers.size>0 #and params[:enable_pn] == "1"
          response = IppbxApi.ippbx_put(ent_username, ent_password, 'ent', 'publicnumber/assign/'+ @public_numbers[0]["number"].to_s+ '/user/' + @ippbx_user_id, nil)
          if response.code == '200'
            params_update = {:public_number =>@public_numbers[0]["number"].to_s}
          Ippbx.update_employee_ippbx params_update,@user.employees[0].id.to_s
          ippbx = Ippbx.find_by_admin_type_and_employee_id("user",@user.employees[0].id.to_s)
          #ippbx.create_c2call_for_employees
          logger.info("Assigned Public Number")
          else
          #flash[:error] = t("controllers.create.error.public_numbers") + t("controllers.create.error.contact_entadmin")
          #redirect_to user_path(@user.id)
          end
        end
	end

        #activate features

        feature_array = ["CW","CT","CCF","CH","VM","C2C","FRK"]
        feature_array.each do |code|
          content_json = {"featureCode" =>  code,"active" => "true"}.to_json
          response = IppbxApi.ippbx_put(user_login + "@" + company_domain, user_password, 'user', 'feature/record', content_json)
          logger.info("activating Features #{response.code}")
        end

        #activate SIMR

        simultaneous_ring_number = ""
        #simultaneous_ring_number+= @public_numbers[0]["number"].to_s + "," if @public_numbers.size>0
        #simultaneous_ring_number+= @user.cellphone + "," unless @user.cellphone.blank?
        simultaneous_ring_number+= @user.cellphone unless @user.cellphone.blank?
        #simultaneous_ring_number+= extension.to_s
        simr_array = simultaneous_ring_number.split(",")
        if simr_array.size > 0
          content_json =  {"featureCode" => "SIMR", "active" => true,  "featureRecord" => {"number" => simultaneous_ring_number, "treatment" => "User is Busy"}}.to_json
          response = IppbxApi.ippbx_put(user_login + "@" + company_domain, user_password, 'user', 'feature/record', content_json)
          if response.code == "200"
          #flash[:notice] = t("controllers.create.ok.enable_ippbx")
          #redirect_to user_path(@user.id)
          else
          #flash[:error] = t("controllers.create.error.feature_simr") + t("controllers.create.error.contact_admin")
          #redirect_to user_path(@user.id)
          end
        else
        #flash[:notice] = t("controllers.create.ok.enable_ippbx")
        #redirect_to user_path(@user.id)
        end

      else
      logger.info("User Creation Failed#{response.body}")
      #redirect_to user_path(@user.id)
      #flash[:error] = t("controllers.create.error.contact_entadmin")
      end
      else
        workphone =  ""
        #flash[:error] = t("controllers.create.error.public_number")
        #redirect_to user_path(@user.id)
      end
      end
    end
  end
  
  
  def remove_company_ippbx company_id
    unless company_id.blank?
      begin
      @spcred = Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
      sp_username = @spcred.login
      sp_password  = Tools::AESCrypt.new.decrypt(@spcred.password)
      @ent = Ippbx.find_by_admin_type_and_company_id("enterprise", company_id.to_s)
      response = IppbxApi.ippbx_get(sp_username, sp_password, 'sp', 'enterpriseadmin/', @ent.uid.to_s)
      if response.code == '200'
        @response_decode = ActiveSupport::JSON.decode(response.body)
        loginName = @response_decode["loginName"]
        emailId = @response_decode["emailId"]
        logger.info "--Email Id=============-----#{emailId}"
        logger.info "--=Login Name============-----#{loginName}"
        delete_response = IppbxApi.ippbx_delete(sp_username, sp_password, 'sp', 'enterprise/', @ent.uid.to_s)
        if delete_response.code == '200'
          #Company.update(params[:id],{:public_numbers => "",:is_ippbx_enabled => '0' })
          @employee = current_user.companies[0].employees
          count = @employee.count
          for i in (0..count-1)
            unless @employee[i].ippbx.blank?
							logger.info("employee .///*****#{@employee[i].id}")
							#Ippbx.find_by_employee_id(@employee[i].id).delete# delete user from IPPBX Table
							employee_name = @employee[i].user.firstname + " " + @employee[i].user.lastname
							begin
								IppbxNotifier.deliver_user_admin_delete(employee_name, @employee[i].user.email) unless @employee[i].user.email.blank?
								IppbxNotifier.deliver_user_admin_delete(employee_name, @employee[i].company_email)
							rescue
							end
            end
          end
        #Employee.update_all("is_ippbx_enabled=0, ippbx_id='', public_number='', extension ='' ", "company_id='"+params[:id].to_s+"'")
        Domain.destroy_domain(company_id)
        #Ippbx.destroy_enterprise_ippbx(params[:id].to_s)
        Ippbx.delete_all "company_id ='" + company_id.to_s + "'"# Delete enterprise from IPPBX Table
        #flash[:notice]  = t("controllers.delete.ok.ippbx")
        #redirect_to company_path(params[:id])
	begin
        IppbxNotifier.deliver_ent_admin_delete(loginName, emailId) unless emailId.blank?
	IppbxNotifier.deliver_ent_admin_delete(loginName, current_user.employees[0].company_email)
	rescue
	end
        else
        logger.info("Company cannot Delete#{delete_response.body}")
        #flash[:error]  = t("controllers.delete.error.ippbx")
        #redirect_to company_path(params[:id])
        end
      else
      #flash[:error]  = t("controllers.delete.error.ippbx")
      #redirect_to company_path(params[:id])
      end
      rescue Exception => e
      #flash[:error] = t("views.notices.ippbx_connect_ent") + "</br>" + e.message
      #redirect_to company_path(company_id)
      end
    end
    

  end
  
  def remove_user_ippbx user_id
      @user = User.find(user_id)
      employee_resultset = @user.employees[0]
      company_resultset = employee_resultset.company
      company_name=company_resultset.name
      company_id = company_resultset.id
      @entcred = Ippbx.find_by_admin_type_and_company_id("enterprise", company_id.to_s)
      unless @entcred.blank?
            ent_username = @entcred.login
            ent_password = Tools::AESCrypt.new.decrypt(@entcred.password)
            @ippx_uid = employee_resultset.ippbx.uid
            unless @ippx_uid.blank?
                  logger.info("IPPBX User Id......&&&&&&#{@ippx_uid}")
                  response = IppbxApi.ippbx_delete( ent_username,  ent_password, 'ent', 'user/', @ippx_uid.to_s)
                  if response.code == '200'
                  employee_id = employee_resultset.id
                  Ippbx.destroy_employee_ippbx(employee_id)
                  User.update(@user.id,{:phone => ""})
                  IppbxNotifier.deliver_user_admin_delete(@user.login, @user.email) unless @user.email.blank?
                  IppbxNotifier.deliver_user_admin_delete(@user.login, @user.employees[0].company_email) 
                  else
                  logger.info("Response Body#{response.body}")
                  end
            end
      end
  end
  
  def availble_public_number company_id
      @public_numbers ||= Array.new
      @entcred = Ippbx.find_by_admin_type_and_company_id("enterprise", company_id.to_s)
      ent_username = @entcred.login
      ent_password = Tools::AESCrypt.new.decrypt(@entcred.password)
      available_response = IppbxApi.ippbx_get(ent_username, ent_password, 'ent', 'publicnumber/', 'available')
      if available_response.code == '200'
      @public_numbers = ActiveSupport::JSON.decode(available_response.body)
      end
      return @public_numbers
  end
    
  def add_public_number company_id, quantity, order_id
    
    @spcred = Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
    sp_username = @spcred.login
    sp_password  = Tools::AESCrypt.new.decrypt(@spcred.password)
    @ent = Ippbx.find_by_admin_type_and_company_id("enterprise", company_id.to_s)
    assigned_number = ""
    response = IppbxApi.ippbx_get(sp_username, sp_password, 'sp', 'publicnumber/', 'available')
    if response.code == '200'
			@public_number = ActiveSupport::JSON.decode(response.body)
			@public_number ||= Array.new
			if !@public_number.blank?
				for i in 0..(quantity-1)
					response2 = IppbxApi.ippbx_put(sp_username,sp_password, 'sp', 'publicnumber/assign/'+ @public_number[i]["number"].to_s + '/enterprise/' + @ent.uid.to_s, nil)

					if response2.code == "200"
						assigned_number = assigned_number + @public_number[i]["number"].to_s + ","
					end
				end 

				assigned_number = assigned_number.chop

				if @ent.extra_numbers.blank?
					prefix = {order_id.to_s => assigned_number}
				else
					prefix = JSON.parse(@ent.extra_numbers)
					prefix[order_id.to_s] = assigned_number
				end

				fields = prefix.to_json

				@ent.update_attributes(:extra_numbers => fields) unless fields.blank?
			end      
		end
  
  end
  
  def remove_public_number company_id, order_id
    @spcred = Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
    sp_username = @spcred.login
    sp_password  = Tools::AESCrypt.new.decrypt(@spcred.password)
    @ent = Ippbx.find_by_admin_type_and_company_id("enterprise", company_id.to_s)
    assigned_numbers = @ent.extra_numbers
    new_string = ""
    if !assigned_numbers.blank?
        assigned_numbers = JSON.parse(assigned_numbers)
        deleted_numbers  = assigned_numbers.delete(order_id.to_s)
	if !deleted_numbers.blank?
	         public_number_array = Array.new
		 public_numbers = deleted_numbers.split(",")
		 public_numbers.each do |public_number|
		        response = IppbxApi.ippbx_put(sp_username, sp_password,'sp', 'publicnumber/unassign/'+ public_number + '/enterprise/' + @ent.uid.to_s, nil)
                 end
	         @ent.update_attributes(:extra_numbers => assigned_numbers.to_json) unless assigned_numbers.blank?
	end
	
    end

  end


end
