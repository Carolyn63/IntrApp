class Spadmin::EnterprisesController < Spadmin::ResourcesController
  def create
    $public_numbers = nil
    company_name = params[:company_name].to_s
    action = params[:commit].downcase
    @form = params[:form].to_i
    case action
    when "cancel"
      session[:ippbx_ent_id] = nil
      session[:ent_details]=nil
      redirect_to  spadmin_enterprises_path
    else
    if @form == 1
    session[:ent_details]={
    :companyname=>params[:enterprise][:name],
    :email=> params[:enterprise][:emailId],
    :locale=> params[:enterprise][:locale],
    :language=> params[:enterprise][:language],
    :extensionlength=>params[:enterprise][:extensionlength],
    :fax=> params[:enterprise][:faxNumber],
    :phone=>params[:enterprise][:phoneNumbers],
    :website=>params[:enterprise][:website],
    :addressline1=> params[:enterprise][:addressLine1],
    :addressline2=> params[:enterprise][:addressLine2],
    :city=> params[:enterprise][:city],
    :state=> params[:enterprise][:state],
    :country=> params[:enterprise][:country],
    :timezone=>params[:enterprise][:timezone],
    :zipcode => params[:enterprise][:zipCode],
    :MN  => params[:enterprise][:MN],
    :VM  => params[:enterprise][:VM],
    :voiceMailBoxMaxLimit => params[:enterprise][:voiceMailBoxMaxLimit],
    :extension =>  params[:enterprise][:extension]
    }
    content_json = {"enterprise" => {"geographicDetails" => {"timezone" => params[:enterprise][:timezone], "zipCode" => params[:enterprise][:zipCode],
    "locale" => params[:enterprise][:locale],"state" => params[:enterprise][:state],
    "language" => params[:enterprise][:language],"addressLine2" => params[:enterprise][:addressLine2],
    "addressLine1" => params[:enterprise][:addressLine1],"city" => params[:enterprise][:city],
    "country" => params[:enterprise][:country]},"name" => params[:enterprise][:name],
    "emailId" => params[:enterprise][:emailId],
    "faxNumber" => params[:enterprise][:faxNumber],"url" => params[:enterprise][:website],
    "featureSet" => params[:enterprise][:featureSet], "extensionLength" => params[:enterprise][:extensionLength],
    "activeStatus" => params[:enterprise][:activeStatus] == "1" ? true : false,
    "domains" => [{"uid" => params[:enterprise][:domains_uid]}],
    "routingDialPlanGroups" => [{"uid" => params[:enterprise][:rdpgs_uid]}]},
    "enterprisePhoneNumberMaps" =>[{"type" => "MN","publicNumber" =>{"number" => params[:enterprise][:MN]}}]}

    unless params[:enterprise][:VM].blank?
    content_json["enterprisePhoneNumberMaps"] << {"type" => "VM","publicNumber" =>{"number" => params[:enterprise][:VM]},
    "extension" => params[:enterprise][:extension]}
    content_json["enterprise"]["voiceMailBoxMaxLimit"] = params[:enterprise][:voiceMailBoxMaxLimit]
    $vm = true
    else
    $vm = false
    end

    content_json= content_json.to_json
    response = IppbxApi.ippbx_post(session[:sp_admin], session[:sp_pass], 'sp', 'enterprise', content_json)
    if response.code == '200'
    #save the created enterprise id
    session[:ippbx_ent_id] = ActiveSupport::JSON.decode(response.body)["uid"]

    session[:sp_ent_name] = params[:enterprise][:name]

    company =Company.find_by_name(params[:enterprise][:name])
    #encrypt_password = Tools::AESCrypt.new.encrypt(params[:user][:password])
    date_time =Time.new.strftime("%Y-%m-%d %H:%M:%S")
    #public_number = Ippbx.retrive_public_number session[:portal_ent_id].to_s
    params_fields = {:uid =>session[:ippbx_ent_id], :admin_type => "enterprise", :name =>params[:enterprise][:name], :company_id=> company.id, :date_created => date_time,:public_number => params[:enterprise][:MN]}
    if $vm 
    params_fields[:vm_number] = params[:enterprise][:VM]
    end  
    Ippbx.create_ippbx params_fields
    ## Domain Table Update
    response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'domain/', params[:enterprise][:domains_uid])
    if response.code == '200'
    @domains = ActiveSupport::JSON.decode(response.body)
    unless @domains.blank?
    params_domain = {:uid => params[:enterprise][:domains_uid], :name =>@domains["name"].downcase, :company_id => company.id}
    Domain.create_domain params_domain
    end
    end

    flash[:notice]  = t("controllers.create.ok.ent_profile")
    session[:ent_details]=nil
    else
    @form -= 1
    flash[:error]  = t("controllers.create.error.ent_profile")  + "<br />" + response.body
    end

    elsif @form == 2
    if session[:ippbx_ent_id].blank?
    @form = 0
    else
    content_json = {"emailHost" => property(:email_host),"emailPort" => property(:email_port),
    "emailPassword" =>property(:email_password), "emailId" => params[:enterprise][:emailId],"entityId" => session[:ippbx_ent_id],"geographicDetails" => {"timezone" => params[:enterprise][:timezone],
    "zipCode" => params[:enterprise][:zipCode], "locale" => params[:enterprise][:locale],"state" => params[:enterprise][:state],
    "language" => params[:enterprise][:language], "addressLine2" => params[:enterprise][:addressLine2],
    "addressLine1" => params[:enterprise][:addressLine2],"city" => params[:enterprise][:city],"country" => params[:enterprise][:country]},
    "type" => 3, "password" => params[:enterprise][:password],"loginName" => params[:enterprise][:loginName]}.to_json
    logger.info "Posting Json Data 2: #{content_json}"

    response = IppbxApi.ippbx_post(session[:sp_admin], session[:sp_pass], 'sp', 'enterpriseadmin', content_json)

    if response.code == '200'
    #insert admin info into ippbx table
    company =Company.find_by_name(session[:sp_ent_name])
    encrypt_password = Tools::AESCrypt.new.encrypt(params[:enterprise][:password])
    #public_number = Ippbx.retrive_public_number session[:portal_ent_id].to_s
    email_password = Tools::AESCrypt.new.encrypt(property(:email_password)) 
    params_fields = {:login =>params[:enterprise][:loginName],  :password=>encrypt_password, :email_host =>property(:email_host), 
                             :email_port => property(:email_port), :email_password => email_password}
    Ippbx.update_enterprise_ippbx params_fields,company.id
    IppbxNotifier.deliver_welcome_ent_admin(params[:enterprise][:loginName], params[:enterprise][:password], params[:enterprise][:emailId])
    user = User.find(company.user_id)
    IppbxNotifier.deliver_welcome_ent_admin(params[:enterprise][:loginName], params[:enterprise][:password], user.employees[0].company_email)
    flash[:notice]  = t("controllers.create.ok.ent_admin_profile")
    else
    @form -= 1
    flash[:error]  = t("controllers.create.error.ent_admin_profile")  + "<br />" + response.body
    end
    end

    elsif @form == 3
    if session[:ippbx_ent_id].blank?
    @form = 0
    else
    features = Array.new(params[:row][:count].to_i)
    for i in 0..(params[:row][:count].to_i - 1)
    features[i] = "{\"featureCode\":\""+params[:featureCode][i.to_s]+"\",\"assigned\":"+ params[:assign][i.to_s].to_s + "}"
    logger.info "-=-=-==--=-^_^#{features[i].to_s}"
    end
    features_str = features.to_sentence(:skip_last_comma => true, :connector => ", ")
    content_json ="{\"enterprise\":{\"uid\":" + session[:ippbx_ent_id] + "},\"features\":[" + features_str + "]}"
    response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'enterprisefeatures', content_json)

    if response.code == '200'
    flash[:notice]  = t("controllers.assign.ok.features")
    else
    @form -= 1
    flash[:error]  = t("controllers.assign.error.features")  + "<br />" + response.body
    end
    end

    elsif @form == 4
    if session[:ippbx_ent_id].blank?
    @form = 0  #return to create user page
    else
    unless params[:number].blank?
    for i in 0..(params[:row][:count].to_i - 1)
    if params[:assign][i.to_s] == true.to_s
    response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/assign/'+ params[:number][i.to_s] + '/enterprise/' + session[:ippbx_ent_id].to_s, nil)
    #response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/assign/'+ params[:number][i.to_s] + '/enterprise/' + params[:id].to_s, nil)
    response_code = response.code
    if response.code != '200'
    do_fail =true
    @form -= 1
    flash[:error]  = t("controllers.assign.error.public_numbers")  + "<br />" + response.body
    end
    end
    end #for
    flash[:notice]  = t("controllers.update.ok.assigned_public_numbers") unless do_fail
    end
       
    #begin
    #@new_number = params[:assign][:pnumber]
    #rescue
    #@new_number = ""
    #end

    #unless @new_number.blank?
    #response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/assign/'+ @new_number + '/enterprise/' + session[:ippbx_ent_id].to_s, nil)
    #if response.code == '200'
    #company =Company.find_by_name(session[:sp_ent_name])
    #params_fields = {:public_number=>@new_number}
    #Ippbx.update_enterprise_ippbx params_fields,company.id

    #flash[:notice]  = t("controllers.update.ok.assigned_public_numbers")
    #session[:company_id] = nil
    #else
    #@form -= 1
    #flash[:error]  = t("controllers.update.error.assigned_public_numbers") + "<br />" + response.body
    #end
    #end
    end
    end

    if action == "next"
    @form += 1
    redirect_to  new_spadmin_enterprise_path(:form => @form)
    elsif action == "finish"
    session[:ippbx_ent_id] = nil
    redirect_to  spadmin_enterprises_path
    end

    end # case
  end

  def new
    @for_update = false
    @form = params[:form].to_i
    @form ||= 1
    @which_form = "form" + @form.to_s
    if @form == 1

      if params[:company_name]!=nil
      session[:ent_details]=nil
      @company_name = CGI::unescape(params[:company_name])
      @addressLine1 = CGI::unescape(params[:address])
      logger.info(@addressLine1)
      @city=CGI::unescape(params[:city])
      @country=CGI::unescape(params[:country])
      @phoneNumbers=CGI::unescape(params[:phone])
      @website=CGI::unescape(params[:website])
      @state = CGI::unescape(params[:state])
      @name= @company_name
      @voiceMailBoxMaxLimit = "20"
      @extension = "1000"
      elsif session[:ent_details]!=nil
      @company_name = session[:ent_details][:companyname]
      @name= session[:ent_details][:companyname]
      @emailId=session[:ent_details][:email]
      @locale=session[:ent_details][:locale]
      @language=session[:ent_details][:language]
      @extensionLength=session[:ent_details][:extensionlength]
      @faxNumber=session[:ent_details][:fax]
      @phoneNumbers = session[:ent_details][:phone]
      @website = session[:ent_details][:website]
      @addressLine1 = session[:ent_details][:addressline1]
      @addressLine2 = session[:ent_details][:addressline2]
      @city = session[:ent_details][:city]
      @state = session[:ent_details][:state]
      @country = session[:ent_details][:country]
      @timezone=session[:ent_details][:timezone]
      @VM = session[:ent_details][:VM]
      @MN = session[:ent_details][:MN]
      @voiceMailBoxMaxLimit = session[:ent_details][:voiceMailBoxMaxLimit]
      @extension = session[:ent_details][:extension]
      end

      ##fill domain list box
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'domain/', 'available')
      if response.code == '200'
      @available_domains = ActiveSupport::JSON.decode(response.body)
      flash[:warning]  = t("controllers.misc.warning.no_available_domain_redirect")  and redirect_to new_spadmin_domain_path  and return if @available_domains.blank?
      else
      flash[:error]  = t("controllers.get.error.domains_list")  + "<br />" + response.body
      end
      ##fill routing plan list box
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'routingdialplangroup/', 'available')
      if response.code == '200'
      @available_rdpgs = ActiveSupport::JSON.decode(response.body)
      flash[:warning]  = t("controllers.misc.warning.no_available_rdpg_redirect") and redirect_to new_spadmin_rdpg_path and return  if @available_rdpgs.blank?
      else
      flash[:error]  = t("controllers.get.error.rdpgs_list")  + "<br />" + response.body
      end
      ## fill public number list box
      logger.info("Available Numbers)))))))))))))))))))))))")
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/', 'available')
      if response.code == '200'
      $available_number = ActiveSupport::JSON.decode(response.body)
      $available_number ||= Array.new
      @MN = $available_number[0]["number"] if $available_number.size>0
      @VM = $available_number[1]["number"] if $available_number.size>1
      flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if @available_number.blank?
      else
      flash[:error]  = t("controllers.get.error.assigned_public_numbers")  + "<br />" + response.body
      end 
      
      ## retrieve features
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'features/', 'all')
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

    elsif @form == 2

    elsif @form == 3
    response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'features/', 'all')
    if response.code == '200'
    @features = ActiveSupport::JSON.decode(response.body)
    flash.now[:warning]  = t("controllers.get.empty.assigned_features") if @features.blank?
    else
    flash[:error]  = t("controllers.get.error.assigned_features")  + "<br />" + response.body
    end
    elsif @form == 4
    if $available_number.size>2
     $public_numbers = $available_number[2..$available_number.size-1]
   # $public_numbers ||= Array.new
   # for i in 2..$available_number.size-1
   #   $public_numbers <<  $available_number[i]["number"]
   #    logger.info("array number*************#{$public_numbers[i]}")
   # end
   # logger.info("array size*************#{$public_numbers.size}")
    @page_results = $public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)                                    
    else
     flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers")
    end
    #if $public_numbers.blank?
    #response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/', 'available')
    #if response.code == '200'
    #$public_numbers = ActiveSupport::JSON.decode(response.body)
    #flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if $public_numbers.blank?
    #else
    #flash[:error]  = t("controllers.get.error.assigned_public_numbers")  + "<br />" + response.body
    #end
    #end
    #$public_numbers ||= Array.new
    #@page_results = $public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
    end
  end

  def update
    $public_numbers = nil
    action = params[:commit].downcase
    @form = params[:form].to_i
    @which_form = "form" + @form.to_s
    case action
    when "cancel"
      redirect_to  ippbx_spadmin_enterprises_path
    else
    if @form == 1

    company = Company.find_by_name(params[:enterprise][:old_name])
    content_json = {"enterprise" =>{"uid" => params[:id].to_i, "geographicDetails" => {"uid" => params[:geographicDetails][:uid].to_i,
    "timezone" => params[:enterprise][:timezone], "zipCode" => params[:enterprise][:zipCode],
    "locale" => params[:enterprise][:locale],"state" => params[:enterprise][:state],
    "language" => params[:enterprise][:language],"addressLine2" => params[:enterprise][:addressLine2],
    "addressLine1" => params[:enterprise][:addressLine1],"city" => params[:enterprise][:city],
    "country" => params[:enterprise][:country]},"name" => params[:enterprise][:name],
    "emailId" => params[:enterprise][:emailId],
    "faxNumber" => params[:enterprise][:faxNumber],"url" => params[:enterprise][:website],
    "extensionLength" => params[:enterprise][:extensionLength],
    "activeStatus" => params[:enterprise][:activeStatus] == "1" ? true : false}}

    unless params[:enterprise][:voiceMailBoxMaxLimit].blank?
    content_json["enterprise"]["voiceMailBoxMaxLimit"] = params[:enterprise][:voiceMailBoxMaxLimit]
    end
    content_json = content_json.to_json
    response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'enterprise', content_json)
    if response.code == '200'
    params_fields = {:name =>params[:enterprise][:name]}
    params_fields[:date_updated] = Time.new.strftime("%Y-%m-%d %H:%M:%S")
    Ippbx.update_enterprise_ippbx params_fields,company.id

    params_company = {
    :name =>params[:enterprise][:name],
    :zipcode => params[:enterprise][:zipCode],
    :state => params[:enterprise][:state],
    :address2 => params[:enterprise][:addressLine2],
    :address => params[:enterprise][:addressLine1],
    :city => params[:enterprise][:city],
    :country => params[:enterprise][:country],
    :website => params[:enterprise][:website]
    }
    Company.find(company.id).update_attributes(params_company)

    flash[:notice]  = t("controllers.update.ok.ent_profile")
    else
    @form -= 1
    flash[:error]  = t("controllers.update.error.ent_profile")  + "<br />" + response.body
    end
    elsif @form == 2
     ippbx = Ippbx.find_by_uid_and_admin_type(params[:enterpriseAdmin][:uid], "enterprise")
    email_password = Tools::AESCrypt.new.decrypt(ippbx.email_password)
    content_json = {"emailHost" => ippbx.email_host,"emailPort" => ippbx.email_port.to_s,
    "emailPassword" =>email_password,"uid" => params[:enterpriseAdmin][:uid].to_i, "emailId" => params[:enterprise][:emailId],
    "geographicDetails" => {"uid" => params[:geographicDetails][:uid].to_i, "timezone" => params[:enterprise][:timezone],
    "zipCode" => params[:enterprise][:zipCode], "locale" => params[:enterprise][:locale],"state" => params[:enterprise][:state],
    "language" => params[:enterprise][:language], "addressLine2" => params[:enterprise][:addressLine2],
    "addressLine1" => params[:enterprise][:addressLine2],"city" => params[:enterprise][:city],"country" => params[:enterprise][:country]}}.to_json

    response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'enterpriseadmin', content_json)
    if response.code == '200'
    flash[:notice]  = t("controllers.update.ok.ent_admin_profile")
    else
    @form -= 1
    flash[:error]  = t("controllers.update.error.ent_admin_profile")  + "<br />" + response.body
    end
    elsif @form == 3
    features = Array.new(params[:row][:count].to_i)
    for i in 0..(params[:row][:count].to_i - 1)
    features[i] = "{\"featureCode\":\""+params[:featureCode][i.to_s]+"\",\"assigned\":"+ params[:assign][i.to_s].to_s + "}"
    end
    features_str = features.to_sentence(:skip_last_comma => true, :connector => ", ")
    content_json ="{\"enterprise\":{\"uid\":" + params[:id] + "},\"features\":[" + features_str + "]}"

    response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'enterprisefeatures', content_json)

    if response.code == '200'
    flash[:notice]  = t("controllers.assign.ok.features")
    else
    @form -= 1
    flash[:error]  = t("controllers.assign.error.features")  + "<br />" + response.body
    end
    elsif @form == 4

    #begin
    #@new_number = params[:assign][:pnumber]
    #rescue
    #@new_number = ""
    #end

    #begin
    #@old_number = params[:assigned_public_number]
    #rescue
    #@old_number = ""
    #end
    
    unless params[:number].blank?
    for i in 0..(params[:row][:count].to_i - 1)
    if params[:assign][i.to_s] == true.to_s
    response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/assign/'+ params[:number][i.to_s] + '/enterprise/' + params[:id].to_s, nil)
    response_code = response.code
    if response.code != '200'
    do_fail =true
    @form -= 1
    flash[:error]  = t("controllers.assign.error.public_numbers")  + "<br />" + response.body
    end
    end
    end #for
    flash[:notice]  = t("controllers.update.ok.assigned_public_numbers") unless do_fail
    end

    #unless @new_number.blank?
    #unless @old_number.blank?
    #logger.info "================#{params[:id]}"
    #IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/unassign/'+ @old_number + '/enterprise/' + params[:id].to_s, nil)
    #end
    #response = IppbxApi.ippbx_put(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/assign/'+ @new_number + '/enterprise/' + params[:id].to_s, nil)
    #logger.info "assigned_public_number: #{params[:assigned_public_number]}"
    #if response.code == '200'

    #params_fields = {:public_numbers => @new_number.to_s}
    #Ippbx.update_enterprise_ippbx params_fields,session[:company_id]

    #flash[:notice]  = t("controllers.update.ok.assigned_public_numbers")
    #session[:company_id] = nil
    #else
    #@form -= 1
    #flash[:error]  = t("controllers.update.error.assigned_public_numbers") + "<br />" + response.body
    #end
    #end
    end

    if action == "next"
    @form += 1
    redirect_to  edit_spadmin_enterprise_path(params["id"], :form => @form)
    elsif action == "finish"
    @form = nil
    redirect_to  ippbx_spadmin_enterprises_path
    end
    end
  end

  def edit
    @for_update = true
    @form = params[:form].to_i
    @form ||= 1
    @which_form = "form" + @form.to_s
    if @form == 1
      #retrieve enterprise
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'enterprise/', params[:id])
      if response.code == '200'
      @response_decode = ActiveSupport::JSON.decode(response.body)
      @name = @response_decode["enterprise"]["name"]
      @emailId = @response_decode["enterprise"]["emailId"]
      @extensionLength = @response_decode["enterprise"]["extensionLength"]
      @faxNumber = @response_decode["enterprise"]["faxNumber"]
      @website = @response_decode["enterprise"]["url"]
      @addressLine1 = @response_decode["enterprise"]["geographicDetails"]["addressLine1"]
      @addressLine2 = @response_decode["enterprise"]["geographicDetails"]["addressLine2"]
      @city = @response_decode["enterprise"]["geographicDetails"]["city"]
      @state = @response_decode["enterprise"]["geographicDetails"]["state"]
      @zipCode = @response_decode["enterprise"]["geographicDetails"]["zipCode"]
      @locale = @response_decode["enterprise"]["geographicDetails"]["locale"]
      @country = @response_decode["enterprise"]["geographicDetails"]["country"]
      @language = @response_decode["enterprise"]["geographicDetails"]["language"]
      @timezone = @response_decode["enterprise"]["geographicDetails"]["timezone"]
      @geographic_details_uid = @response_decode["enterprise"]["geographicDetails"]["uid"]
      @available_domains = ""
      @available_rdpgs = ""
      @uid = params[:id]
      @voiceMailBoxMaxLimit = @response_decode["enterprise"]["voiceMailBoxMaxLimit"]
      logger.info("MAp&&&&&&&&&&&&&&#{@response_decode["enterprisePhoneNumberMaps"]}")
      ent_map = @response_decode["enterprisePhoneNumberMaps"]
      ent_map ||= Array.new
      @VM = ent_map[1]["publicNumber"]["number"]
      @MN = ent_map[0]["publicNumber"]["number"]
      @extension = ent_map[1]["extension"]
      else
      flash[:error]  = t("controllers.get.error.ent_profile")  + "<br />" + response.body
      end
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'enterprisefeatures/assigned/', params[:id])
      if response.code == '200'
        @sp_features = ActiveSupport::JSON.decode(response.body)
        flash.now[:warning]  = t("controllers.get.empty.assigned_features") if @sp_features.blank?
        unless @sp_features.blank?
          @sp_features.each do |feature|
            logger.info(feature)
            logger.info("checking Features---------------------")
            if feature["featureCode"] == "VM"
            logger.info("true")
            @show_vm = true
            end
          end
        end
      else
      flash[:error]  = t("controllers.get.error.assigned_features")  + "<br />" + response.body
      end
    elsif @form == 2
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'enterpriseadmin/', params[:id])
      if response.code == '200'
      @response_decode = ActiveSupport::JSON.decode(response.body)
      @loginName = @response_decode["loginName"]
      @emailId = @response_decode["emailId"]
      #@password = @response_decode["password"]
      @password = ""
      @addressLine1 = @response_decode["geographicDetails"]["addressLine1"]
      @addressLine2 = @response_decode["geographicDetails"]["addressLine2"]
      @locale = @response_decode["geographicDetails"]["locale"]
      @city = @response_decode["geographicDetails"]["city"]
      @state = @response_decode["geographicDetails"]["state"]
      @zipCode = @response_decode["geographicDetails"]["zipCode"]
      @country = @response_decode["geographicDetails"]["country"]
      @language = @response_decode["geographicDetails"]["language"]
      @timezone = @response_decode["geographicDetails"]["timezone"]
      @geographic_details_uid = @response_decode["geographicDetails"]["uid"]
      @enterprise_admin_uid = @response_decode["uid"]
      @uid = params[:id]
      elsif response.code == '400' and response.body.include? 'No admin record found'
      session[:ippbx_ent_id] = params[:id]
      flash[:warning]  = t("controllers.misc.warning.edit_non_created_ent_admin")
      redirect_to new_spadmin_enterprise_path(:form => @form)
      else
      flash[:error]  = t("controllers.get.error.ent_admin_profile")  + "<br />" + response.body
      end
    elsif @form == 3
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'features/', 'all')
      if response.code == '200'
      @features = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.get.empty.assigned_features") if @features.blank?
      else
      flash[:error]  = t("controllers.get.error.assigned_features")  + "<br />" + response.body
      end
    elsif @form == 4
      if $public_numbers.blank?
        response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'publicnumber/', 'available')
        if response.code == '200'
        $public_numbers = ActiveSupport::JSON.decode(response.body)
        flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if $public_numbers.blank?
        else
        flash[:error]  = t("controllers.get.error.assigned_public_numbers") + "<br />" + response.body
        end
      end

    $public_numbers ||= Array.new
    #just return the first number, the whole code might need to be change, so, temperaly changed to: [0..0]
    #@page_results = $public_numbers[0..0].paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
    @page_results = $public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
    #resp = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'enterprise/', params[:id])
    #@response_decode = ActiveSupport::JSON.decode(resp.body)
    #@name = @response_decode["enterprise"]["name"]
    #company = Company.find_by_name(@name)
    #logger.info("name*******************#{@name}")
    #session[:company_id]=company.id
    #@assigned_number = Ippbx.find_by_company_id_and_admin_type(session[:company_id],"enterprise").public_number
    end

  end

  def index
    @result=0
    if params[:search].blank?
    @companies = Company.find_by_sql("select c.* from companies c left join ippbxes i on c.id=i.company_id where i.id is null").paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
    elsif params[:search].blank?
    @companies = Company.find_by_sql("select c.* from companies c left join ippbxes i on c.id=i.company_id where i.id is null").paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
    @result=@companies.count()
    else
      @companies = Company.find_by_sql("select c.* from companies c left join ippbxes i on c.id=i.company_id where i.id is null and c.name regexp '"+addslash(params[:search])+"'").paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
      @result=@companies.count()
      if @result==0
      flash.now[:warning] = t("controllers.search.empty")
      end
    end
  end

  def ippbx
    if params[:commit] == 'Search'
      criteria = 'criteria={'
      criteria += 'name:'+CGI::escape(params[:name].strip) + ';' unless params[:name].strip.blank?
      criteria += 'emailId:'+CGI::escape(params[:emailId].strip) + ';' unless params[:emailId].strip.blank?
      criteria += 'activeStatus:'+CGI::escape(params[:activeStatus].strip) + ';' unless params[:activeStatus].strip.blank?
      criteria += 'city:'+CGI::escape(params[:city].strip) + ';' unless params[:city].strip.blank?
      criteria += '}'
      response = ippbx_search('sp', 'resource=Enterprise&orderBy=name&sortOrder=asc&', criteria)
      if response.code == '200'
      @enterprises = ActiveSupport::JSON.decode(response.body)
      flash.now[:warning]  = t("controllers.search.empty") if @enterprises.blank?
      else
      flash[:error]  = t("controllers.search.error.enterprises_list")  + "<br />" + response.body
      end
    else
      response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'enterprise/', 'all')
      if response.code == '200'
      @enterprises = ActiveSupport::JSON.decode(response.body)
			logger.info "@enterprises: #{@enterprises}"
      else
      flash[:error]  = t("controllers.get.error.enterprises_list")  + "<br />" + response.body
      end
    flash.now[:warning]  = t("controllers.get.empty.enterprises_list") unless !@enterprises.blank?
    end
    #@companies= Company.find_by_name()
    @enterprises ||= ''
  end

  def destroy
    company_name = params[:company_name].to_s
    response = IppbxApi.ippbx_get(session[:sp_admin], session[:sp_pass], 'sp', 'enterpriseadmin/', params[:id])
    if response.code == '200'
    @response_decode = ActiveSupport::JSON.decode(response.body)
    loginName = @response_decode["loginName"]
    emailId = @response_decode["emailId"]
    end
    if !params[:id].blank?
      response = IppbxApi.ippbx_delete(session[:sp_admin], session[:sp_pass], 'sp', 'enterprise/', params[:id])
      if response.code == '200'
        flash[:notice]  = t("controllers.delete.ok.enterprise")
        ippbx = Ippbx.find_by_admin_type_and_uid("enterprise", params[:id])
        company = Company.find(ippbx.company_id)
        unless company.blank?
        Ippbx.delete_all "company_id ='" + company.id.to_s + "'"
	#Ippbx.destroy_enterprise_ippbx(company.id)
        user = User.find(company.user_id)
        Domain.destroy_domain(company.id)
        end
      IppbxNotifier.deliver_ent_admin_delete(loginName, emailId) unless emailId.blank?
      IppbxNotifier.deliver_ent_admin_delete(loginName, user.employees[0].company_email)
      else
      flash[:error]  = t("controllers.delete.error.enterprise")  + "<br />" + response.body
      end
    end
    redirect_to  ippbx_spadmin_enterprises_path
  end

end

