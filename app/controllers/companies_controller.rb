class CompaniesController < PortalIppbxController
  attr_accessor :mobile_tribe_create

  # Do before the controller is called 
  before_filter :require_user
  before_filter :find_user
  before_filter :find_company, :only => [:show,:edit, :update, :profile, :show, :destroy]
  before_filter :only_allowed_user, :only => [:show, :profile]
  before_filter :only_owner, :only => [:edit, :update, :destroy]
  before_filter :recently_companies, :only => [:index, :show, :profile]
  before_filter :check_active_companies, :only => [:new, :create]

  before_filter :require_https, :only => [:services, :payments]
  before_filter :require_http, :except => [:services, :payments] 
  
  require 'json'
  # sortable_attributes :name, :address, :city, :phone, :company_type, :industry, :size, :team, :privacy, :created_at

  def index
    #@companies = Company.by_search(params[:search]).by_public_and_employers(current_user.id).paginate :page => params[:page], :order => "name ASC"
    #@companies = Company.by_public_and_employers(current_user).paginate(:page => params[:page], :order => "name ASC")
    @companies = Company.search_or_filter_companies(current_user, params)
    
  end

  def mn_as_aa
    response = IppbxApi.ippbx_get(session[:ent_admin], session[:ent_pass], 'ent', 'features/autoattendant/', 'all')
    if response.code == '200'
    @ent_feature_rec = ActiveSupport::JSON.decode(response.body)
    logger.info ">>>>>>>>>>>>>>#{@ent_feature_rec}"  
    end
    redirect_to company_path(params[:id])
  end
 
  def tf_as_aa
    redirect_to company_path(params[:id])
  end
  
  def filerecord
    redirect_to company_path(params[:id])
  end

  def profile
    @active_employees = @company.active_user_employees.paginate :page => params[:page]
  end
  
  def add_company_ippbx
    #@spcred = Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
    @spcred = Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
    sp_username = @spcred.login
    sp_password  = Tools::AESCrypt.new.decrypt(@spcred.password)
    company_id=params[:id]
    company = Company.find(company_id)
    # Domain Creation
    if company.domain_name.blank?
      domain_name = company.name.gsub(" ","")
    else
      domain_name = company.domain_name
    end
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
       
				content_json ={"enterprise" => {"geographicDetails" => {"timezone" => property(:default_timezone), "zipCode" => company.zipcode,
        "locale" =>property(:default_locale),"state" => company.state,
        "language" => property(:default_language),"addressLine2" => company.address2,
        "addressLine1" => company.address,"city" => company.city,
        "country" => company.country},"name" => company.name,
        "emailId" => current_user.email,
        "faxNumber" =>"","url" => company.website,
        "featureSet" => "all", "extensionLength" => "4",
        "activeStatus" => "true","domains" => [{"uid" =>@domain_id["uid"]}],
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
            IppbxNotifier.deliver_welcome_ent_admin(ent_username, ent_password, current_user.email)
	    IppbxNotifier.deliver_welcome_ent_admin(ent_username, ent_password, current_user.employees[0].company_email)
          else
          logger.info("Admin Failed$$$$$$$$$$$#{admin_response.body}")
          flash[:error]=t("controllers.create.error.contact_spadmin")
          redirect_to company_path(company_id)
          end
          # Assign Features.....t
          features_str = "{\"featureCode\":\"all\",\"assigned\":true}"
          features_content_json ="{\"enterprise\":{\"uid\":" + @ent["uid"] + "},\"features\":[" + features_str + "]}"
          logger.info("Posting Json features #{features_content_json}")
          features_response = IppbxApi.ippbx_put(sp_username,sp_password, 'sp', 'enterprisefeatures', features_content_json)
          if features_response.code=='200'
            logger.info("Feature assigned for Company")
          else
            flash[:error]=t("controllers.create.error.contact_spadmin")
            redirect_to company_path(company_id)
          end
          #Assign Public Number
          if !$public_number.blank?
          @numbers = ""
          for i in 2..6 # assign 5 public numbers for Enterprise 
            response = IppbxApi.ippbx_put(sp_username,sp_password, 'sp', 'publicnumber/assign/'+ $public_number[i]["number"].to_s + '/enterprise/' + @ent["uid"], nil)
            if response.code != '200'
              do_fail =true
              flash[:error]=t("controllers.create.error.public_numbers") + " " + t("controllers.create.error.contact_spadmin") and redirect_to company_path(company_id)
            end
            #@numbers += $public_number[i]["number"] + ","
         end #for
	 #Updat only MN not all public_numbers
         #@numbers = @numbers.chop
         #params_update = {:public_number =>@numbers}
         #logger.info("parameters for update #{params_update}")
         #Ippbx.update_enterprise_ippbx params_update, company.id
         flash[:notice] = t("controllers.create.ok.enable_ippbx") and redirect_to company_path(company_id) unless do_fail
         end

        else
        delete_rdpg_response = IppbxApi.ippbx_delete(sp_username,sp_password, 'sp', 'routingdialplangroup/', @rdpgs_id["uid"])
        delete_domain_response = IppbxApi.ippbx_delete(sp_username,sp_password, 'sp', 'domain/', @domain_id["uid"])
        if delete_domain_response.response =='200'
        Domain.destroy_domain(company_id)
        end
        redirect_to company_path(company_id)
        logger.info("response body#{response.body}")
        flash[:error]=t("controllers.create.error.contact_spadmin")
        end
      else
        flash[:error]=t("controllers.create.error.contact_spadmin")
        redirect_to company_path(company_id)
      end
    else
      flash[:error]=t("controllers.create.error.contact_spadmin")
      logger.info("RDPGS body#{rdpgs_response.body}")
      redirect_to company_path(company_id)
    end
  #=end
  #redirect_to company_path(params[:id])
  end
  
   def removeippbx
    unless params[:id].blank?
      @spcred = Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
      sp_username = @spcred.login
      sp_password  = Tools::AESCrypt.new.decrypt(@spcred.password)
      @ent = Ippbx.find_by_admin_type_and_company_id("enterprise", params[:id].to_s)
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
            IppbxNotifier.deliver_user_admin_delete(employee_name, @employee[i].user.email) unless @employee[i].user.email.blank?
	    IppbxNotifier.deliver_user_admin_delete(employee_name, @employee[i].company_email)
            end
          end
        #Employee.update_all("is_ippbx_enabled=0, ippbx_id='', public_number='', extension ='' ", "company_id='"+params[:id].to_s+"'")
        Domain.destroy_domain(params[:id])
        #Ippbx.destroy_enterprise_ippbx(params[:id].to_s)
        Ippbx.delete_all "company_id ='" + params[:id].to_s + "'"# Delete enterprise from IPPBX Table
        flash[:notice]  = t("controllers.delete.ok.ippbx")
        redirect_to company_path(params[:id])
        IppbxNotifier.deliver_ent_admin_delete(loginName, emailId) unless emailId.blank?
	IppbxNotifier.deliver_ent_admin_delete(loginName, current_user.employees[0].company_email)
        else
        logger.info("Company cannot Delete#{delete_response.body}")
        flash[:error]  = t("controllers.delete.error.ippbx")
        redirect_to company_path(params[:id])
        end
      else
      flash[:error]  = t("controllers.delete.error.ippbx")
      redirect_to company_path(params[:id])
      end
    end

  end

  def new
    @company = Company.new
    @company.user_id = current_user.id
    @company.privacy = Company::Privacy::PUBLIC

    @owner_help_url = HelpUrl.find_help_url(:controller => "companies", :action => "new", :url_params => "owner=1")
  end

  # Last one, to make sure that I've actually got the setup right.
  def create
    phone_number = params[:company][:phone].gsub(/0/x,"")
    phone_number= phone_number.gsub(" ","")
    logger.info("phnumberrrrrrrrrrrrrrrrrrrrrrrrr----->>>>>#{phone_number}")
    params[:company][:company_phone] =params[:company][:country_phone_code]+phone_number
     if !params[:company][:website].blank? # Adding http:// by default
      unless  params[:company][:website] =~ %r{\Ahttps?:\/\/\w}i
      params[:company][:website] = "http://" + params[:company][:website]
      end
     end

    params[:company][:facebook], params[:company][:facebook], params[:company][:facebook] = validate_social_url(params[:company][:facebook],  params[:company][:twitter],  params[:company][:linkedin])
    @company = Company.new(params[:company])
    @company.user_id = current_user.id    
    params[:employee][:phone] = @company.phone
    @employee = @company.employees.build(params[:employee])
    success = @employee.valid?
    success &= @company.save
    if success && @company.errors.empty?
      message = @employee.sogo_connect! ? "" : t("controllers.problem_with_sogo_account") + "#{@employee.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
      flash[:notice]  = t("controllers.company_successful_created")
      flash[:error] = message unless message.blank?
      if params[:redirect_to] == 'add_employee'
        redirect_to new_company_employee_path(:company_id => @company.id)
      else
        if message.blank?
          redirect_to company_create_user_ondeego_path(current_user, :company_id => @company.id)
        else
          redirect_to company_path(@company)
        end
      end
    else
      #Skip phone error  message for employee, we show this message for company
      @employee.filter_error_messages(["phone"])
      flash.now[:error]  = t("controllers.company_create_failed")
      render :action => "new"
    end
  end

  # Another test of the portal 
  def edit
    @employee = @company.employee(current_user)
    @departments = @company.departments.all
  end
  
  def update
    logger.info(params[:company])
    phone_number = params[:company][:phone].gsub(/0/x,"")
    phone_number= phone_number.gsub(" ","")
    params[:company][:company_phone] =params[:company][:country_phone_code]+phone_number
    if !params[:company][:website].blank?
      unless params[:company][:website] =~ %r{\Ahttps?:\/\/\w}i
      params[:company][:website] = "http://" + params[:company][:website]
      end
    end
    social_urls = Array.new 
    social_urls = validate_social_url(params[:company][:facebook],  params[:company][:twitter],  params[:company][:linkedin] )
    params[:company][:facebook] = social_urls[0]
    params[:company][:twitter] = social_urls[1]
    params[:company][:linkedin] = social_urls[2]
    if property(:use_ippbx)
    unless @company.ippbx.blank?
      if edit_ippbx_enterprise(params[:company], @company)
        #update_company @company
        update_company params[:company]
      else
        flash.now[:error]  = t("controllers.company_update_failed")
        render :action => "edit"
      end
    else
      update_company params[:company]
    end
    else
      update_company params[:company]
    end
  end
  
  def update_company company
    @employee = @company.employee(current_user)
    logger.info(company)
    @company.attributes = company
    if @company.save && @company.errors.empty?
      flash[:notice] = t("controllers.company_updated")
      if params[:redirect_to] == 'add_employee'
        redirect_to new_company_employee_path(:company_id => @company.id)
      else
         redirect_to company_path(company)
	#redirect_to user_companies_path(current_user.id)
      end
    else
      @departments = @company.departments.all
      flash.now[:error]  = t("controllers.company_update_failed")
      render :action => "edit"
    end
  end

  def show
    
  end

  def application
    self.allow_forgery_protection = false
    @applications = @user.employers.active_employers.paginate :page => params[:page], :order => "name DESC"
  end

  def destroy
   if property(:use_ippbx)
    unless @company.ippbx.blank?
    destroy_ippbx_enterprise(@company.id)
    end
   end 
   
    unless @company.cloudstorage.blank?
      PortalCloudstorageController.new.remove_company @company.id
    end
    
    if @company.destroy && @company.errors.empty?
      flash[:notice] = t("controllers.company_successful_deleted")
    else
      flash[:error] = t("controllers.failed_delete_company") + "#{@company.errors.on_base.blank? ? '' : @company.errors.on_base}"
    end
    redirect_to root_path
  end

  def stats
  end
  
  protected

  def find_company
    @company = Company.find_by_id params[:id]
    report_maflormed_data if @company.blank?
  end

  def find_user
    unless params[:user_id].blank?
      @user = User.find_by_id params[:user_id]
      report_maflormed_data unless @user == current_user
    end
  end

  def only_allowed_user
    report_maflormed_data(t("controllers.access_denied")) unless current_user.can_view_company_profile?(@company)
  end

  def only_owner
    report_maflormed_data unless @company.admin == current_user
  end

  def recently_companies
    @recently_companies = Company.public.all :limit => 5, :order => "created_at DESC"
  end

	def check_active_companies
		if !property(:multi_company) && !current_user.companies.blank? && !current_user.employees.blank?
			flash[:error] = t("controllers.users_may_be_employee_only_one_company")
			redirect_to root_path
		end
	end

 def validate_social_url(*options)

	 #facebook = http://www.facebook.com/otogo, twitter = http://www.twitter.com/otogo , linkedin = http://www.linkedin.com/company/2679523
         facebook_url, twitter_url, linkedin_url = ""
	 i = 0
	 options.each do |option|
           
	   unless option.blank?
	              unless option =~ %r{\Ahttps?:\/\/\w}i
		      option = "http://" + option
		      end
		      logger.info("company_url#{option}")
		      if (option =~  %r{\Ahttps?:\/\/www.facebook.com\/\w}i) and i == 0
			facebook_url = option
		      elsif (option =~  %r{\Ahttps?:\/\/www.twitter.com\/\w}i) and i == 1
			twitter_url = option 
		      elsif (option =~ %r{\Ahttps?:\/\/www.linkedin.com\/company\/\d}i)  and i ==2
			linkedin_url = option
		      end
	   end
	   i = i+1
	 end
	 logger.info("Facebook_url #{facebook_url},twitter_url #{twitter_url} ,linkedin_url #{linkedin_url}")
	 return facebook_url, twitter_url, linkedin_url
 
 end

end
