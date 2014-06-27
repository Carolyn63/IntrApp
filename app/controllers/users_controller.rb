require 'oauth'
class UsersController < PortalIppbxController
  before_filter :require_no_user, :only => [:new, :create, :confirmation, :spiceworks]
  before_filter :require_user, :only => [:edit, :update, :destroy, :show, :contacts, :friends, :index, :friendship_request, :friendship_delete, :addippbx, :removeippbx, :generate_user_payment_requests, :payment_requests]
  before_filter :find_user, :only => [:destroy, :edit, :update, :show, :contacts, :friends, :friendship_request, :friendship_delete, :remove_mt_association]
  before_filter :company_pending, :only => [:show]
  before_filter :only_allowed_user, :only => [:show]
  before_filter :only_owner, :only => [:destroy, :edit, :update, :contacts, :friends, :friendship_request, :friendship_delete, :remove_mt_association]
  before_filter :find_friend, :only => [:friendship_request, :friendship_delete]
  before_filter :require_https, :only => [:services, :payments]
  before_filter :require_http, :except => [:services, :payments] 
  protect_from_forgery :except => [:payment_thanks]
  #before_filter :check_mobile_tribe_user, :only => [:create, :update]
  require 'json'

  	def spiceworks
		@consumer=OAuth::Consumer.new property(:spiceworks_consumer_key), 
                              property(:spiceworks_consumer_secret_key), 
                              {:site=>"http://community.spiceworks.com"}

		@request_token=@consumer.get_request_token(:oauth_callback => property(:app_site)+"/signup")

		# session[:request_token].authorize_url has to be changed #jhlee
		session[:request_token] = @request_token

		logger.info("request URL... #{@request_token.authorize_url}")
		@redirection_url = @request_token.authorize_url 
		@redirection_url = @redirection_url.sub("oauth", "public_oauth")

		@redirection_url = URI::escape(@redirection_url)
		
		logger.info("@redirection_url:  #{@redirection_url}")
		render :partial => "spiceworks"
	end
  
  def c2xcall
    render :partial=>"c2xcall"
  end
  
  def client_configuration

  end 
    
  def addippbx
   unless params[:id].blank?
      @user = User.find(params[:id])
      extension=''
      user_login = @user.login
      user_password = Tools::AESCrypt.new.decrypt(@user.user_password)
      company_resultset = @user.employees[0].company
      #company_name =current_user.employees[0].company.name
      #company_id =current_user.employees[0].company.id
      company_name = company_resultset.name
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
      if @public_numbers.size>0
				workphone = @public_numbers[0]["number"]
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
      #content_json = {"password" => user_password,"featureSet" => "11111111111110",
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
        params_create = {:uid =>@ippbx_user_id, :admin_type => "user", :name =>@user.firstname+ " " + @user.lastname, :login=>user_login, :password => encrypt_password, :company_id=> company_id.to_s, :employee_id => @user.employees[0].id.to_s,:extension=> extension.to_s, :mobile_number => @user.cellphone,:date_created => date_time}
        Ippbx.create_ippbx params_create
        #ActiveRecord::Base.connection.execute("INSERT INTO ippbxes (uid, admin_type, name, login, password, company_id,employee_id,date_created) VALUES ('"+addslash(@ippbx_user_id)+"','user','"+addslash(current_user.firstname+ " " + current_user.lastname)+"','"+addslash(user_login)+"',AES_ENCRYPT('"+user_password+"', '"+property(:cryptpass)+"'),'"+addslash(company_id.to_s)+"','"+addslash(current_user.employees[0].id.to_s)+"',NOW())")
        begin
	IppbxNotifier.deliver_welcome_user_admin(user_login, user_password, @user.email)
	IppbxNotifier.deliver_welcome_user_admin(user_login, user_password, @user.employees[0].company_email)
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
        flash[:error] = t("controllers.create.error.features") + t("controllers.create.error.contact_entadmin")
        end
        #assign public Number

        #if @public_numbers.size>0 and params[:enable_pn] == "1"
        if @public_numbers.size>0
          response = IppbxApi.ippbx_put(ent_username, ent_password, 'ent', 'publicnumber/assign/'+ @public_numbers[0]["number"].to_s+ '/user/' + @ippbx_user_id, nil)
          if response.code == '200'
            params_update = {:public_number =>@public_numbers[0]["number"].to_s}
          Ippbx.update_employee_ippbx params_update,@user.employees[0].id.to_s
					ippbx = Ippbx.find_by_admin_type_and_employee_id("user",@user.employees[0].id.to_s)
					ippbx.create_c2call_for_employees
          logger.info("Assigned Public Number")
          else
          flash[:error] = t("controllers.create.error.public_numbers") + t("controllers.create.error.contact_entadmin")
          redirect_to user_path(@user.id)
          end
        end

        #activate features

        feature_array = ["CW","CT","CCF","CH","VM","C2C","FRK"]
        feature_array.each do |code|
          content_json = {"featureCode" =>  code,"active" => "true"}.to_json
          response = IppbxApi.ippbx_put(user_login, user_password, 'user', 'feature/record', content_json)
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
          response = IppbxApi.ippbx_put(user_login, user_password, 'user', 'feature/record', content_json)
          if response.code == "200"
          flash[:notice] = t("controllers.create.ok.enable_ippbx")
          redirect_to user_path(@user.id)
          else
          flash[:error] = t("controllers.create.error.feature_simr") + t("controllers.create.error.contact_admin")
          redirect_to user_path(@user.id)
          end
        else
        flash[:notice] = t("controllers.create.ok.enable_ippbx")
        redirect_to user_path(@user.id)
        end

      else
      logger.info("User Creation Failed#{response.body}")
      redirect_to user_path(@user.id)
      flash[:error] = t("controllers.create.error.contact_entadmin")
      end
      else
        workphone =  ""
        flash[:error] = t("controllers.create.error.public_number")
        redirect_to user_path(@user.id)
      end
      end
    end
  end

  def removeippbx
    unless params[:id].blank?
      @user = User.find(params[:id])
      #company_name=@user.employees[0].company.name
      #company_id = @user.employees[0].company.id
      logger.info("-------------------#{@user.id}")
      employee_resultset = @user.employees[0]
      company_resultset = employee_resultset.company
      company_name=company_resultset.name
      company_id = company_resultset.id
      @entcred = Ippbx.find_by_admin_type_and_company_id("enterprise", company_id.to_s)
      ent_username = @entcred.login
      ent_password = Tools::AESCrypt.new.decrypt(@entcred.password)
      @ippx_uid = employee_resultset.ippbx.uid
      logger.info("IPPBX User Id......&&&&&&#{@ippx_uid}")
      response = IppbxApi.ippbx_delete( ent_username,  ent_password, 'ent', 'user/', @ippx_uid.to_s)
      if response.code == '200'
      employee_id = employee_resultset.id
      #Employee.update(employee_id,{:is_ippbx_enabled => 0, :ippbx_id => "",:public_number => "", :extension => ""})
      Ippbx.destroy_employee_ippbx(employee_id)
      User.update(@user.id,{:phone => ""})
      logger.info("ippbx disabled...............>>>>>>>>")
      flash[:notice]  = t("controllers.delete.ok.ippbx")
      redirect_to user_path(@user.id)
      begin
      IppbxNotifier.deliver_user_admin_delete(@user.login, @user.email) unless @user.email.blank?
      IppbxNotifier.deliver_user_admin_delete(@user.login, @user.employees[0].company_email) 
      rescue
      end
      else
      logger.info("Response Body#{response.body}")
      redirect_to user_path(@user.id)
      flash[:error]  = t("controllers.delete.error.ippbx")
      end
    end
  end
    
 def voice_mail
   render :partial => "voice_mail"
 end
 
 def update_voice_mail
   
 end
  
  def index
    @users = User.search_or_filter_users(current_user, params)
    @recently_users = User.public_and_coworkers(current_user).all(:order => "created_at DESC", :limit => 5)
  end

  def confirmation
  end
  
 
	def destroy
		if @user.destroy
			flash[:notice] = t("controllers.user_success_deleted")
			redirect_to root_url
		else
			flash[:notice] = t("controllers.failed_user_delete")
			render :action => :show
		end
	end
  # GET/signup
  # Directs to the signup page
  
  def code_image   
    if session[:code].blank?
      image = ValidateImage.new(6)
      session[:code] = image.code      
    else 
      image = ValidateImage.new(session[:code].to_s)
    end
    
    # image = ValidateImage.new(6)
    # session[:code] = image.code     
    send_data image.code_image, :type => 'image/jpeg', :disposition => 'inline'
  end   
  
  def refresh_code_image   
    image = ValidateImage.new(6)
    session[:code] = image.code     
    send_data image.code_image, :type => 'image/jpeg', :disposition => 'inline'
  end  
  
  
  def new
      logger.info("Linkedin Merge#{session[:linkedin_merge].to_s}")
      if session[:user_reg].blank?      
      @user = User.new  
	  unless session[:linkedin_merge]
	  session[:linkedin_signup] = nil
	  session[:member_id] = nil	
	  end
    else
      @user = session[:user_reg]
      session[:user_reg] = nil 
    end
	if session[:linkedin_merge]
	    session[:linkedin_signup] =  "true"
	else
		@member_id = session[:member_id]	  
	    session[:member_id] = nil
	end
	
	if params[:oauth_token].present? and params[:oauth_verifier].present?
			logger.info(session[:request_token])
			@access_token=session[:request_token].get_access_token(:oauth_verifier => params[:oauth_verifier], :oauth_signature_method => "HMAC-SHA1")
			#resoponse = @access_token.get "/user/profile_data?format=json"
			response = @access_token.request(:get, "/user/profile_data?format=json" )
			spicework_user = JSON.parse response.body
			logger.info("code >>>>#{response.code}")
			logger.info("Body >>>>#{spicework_user}")
			logger.info("FirstName #{spicework_user["firstname"]}")
			if response.code == "200"
			   #do login code
			   @spiceworks_success = "200"
			   	session[:spice_fname] = spicework_user["firstname"]
			   	session[:spice_lname] = spicework_user["lastname"]
			 	session[:spice_email] = spicework_user["email"]
			   session[:error_message] = "Login Success"
			elsif response.code == "401"
			   @spiceworks_success = "401"
			   session[:error_message] = "Spiceworks Authentication Failed."
			   flash[:notice] = "Spiceworks Authentication Failed."
			end
        elsif params[:spice_works]
		#
		else
		@spiceworks_success = ""
		session[:spice_fname] = nil
		session[:spice_lname] = nil
		session[:spice_email] = nil
	end
	
	
    logger.info("Linkedin Signup#{session[:linkedin_signup].to_s}")
	@input_captcha = ""
    @password = ""
    @confirmed_password = ""
    render :layout => "signup" 
	
  end
  
  def linkedin_signup
    logger.info("Linkedin Signup remote>>>>>>")
    session[:linkedin_signup] = true
	render :partial => "linkedin_signup"
   end
  
  def linkedin_signin
    
    logger.info("Linkedin Signin remote>>>>>>")
    session[:linkedin_signin] = true
	render :partial => "linkedin_signin"
	end


	def create	  
	 params[:user] = remove_space(params[:user])
     if session[:linkedin_signup] or session[:spice_lname]
	    params[:user][:login] = generate_login(params[:user][:email])
		password = generate_password(8)
		params[:user][:password] = 	password 
		params[:user][:password_confirmation] = password 
		session[:member_id] = params[:user][:memberid]
	 else
		 @password = params[:user][:password].to_s
		 @confirmed_password = params[:user][:password_confirmation].to_s
		 if @password!=@confirmed_password
			@password = ""
			@confirmed_password = ""
		 end
	 end
	session[:user_reg] = User.new(params[:user])
	@user = User.new(params[:user])
	logger.info("User Params#{params[:user]}")
    @user.self_register = true
    @user.mobile_tribe_create = true
    
unless session[:linkedin_signup] or session[:spice_lname]
	   @input_captcha = params[:user][:captcha]
     logger.info "captcha code: #{@input_captcha}" 	   
	   unless session[:code]==@input_captcha
       flash[:error]='Captcha entered is incorrect!'
       session[:code] = nil
       @input_captcha = ""
       render :action => :new, :layout => "signup"
       return
	   end
end
if session[:linkedin_signup]
user3p_id =  params[:user][:memberid] 
network = "linkedin"
profile_url = "http://www.linkedin.com/profile/view?id=#{params[:user][:memberid]}"
elsif session[:spice_lname]
user3p_id = params[:user][:email]
network = "spiceworks"
profile_url = "http://www.spiceworks.com"
end
user3p =  User3p.find_by_member_id(user3p_id)
if user3p.blank?
               
		if @user.save
                  if  session[:linkedin_signup] or session[:spice_lname]
                      session[:linkedin_signup] = nil
					  session[:spice_fname] = nil
					  session[:spice_lname] = nil
					  session[:spice_email] = nil
                      @user.deliver_welcome!
                      @user3p = User3p.new(:member_id => user3p_id, :user_id => @user.id, :network => network, :created_at => Time.new.strftime("%Y-%m-%d %H:%M:%S"), :profile_url => profile_url)
@user3p.save
create_linkedin_company(params[:user][:memberid], @user) if session[:linkedin_signup]
logger.info("Current User #{@user.id} #{@user.name}")
session[:member_id] = nil	
                      redirect_to root_path
                      
                  else           
					  #clear captcha session
					  session[:code] = nil
					  #clear reg form session
					  session[:user_reg] = nil
					  #change status to block
					   
					  @user.change_status 3
					  @user.deliver_confirm!
					  #flash[:notice] = "Your account create."		  
					  render :action => :confirmation, :layout => "signup"
                  end
		else
			render :action => :new, :layout => "signup"
		end
	else
		    user = User.find_by_id(user3p.user_id)
			@user_session = UserSession.new(:login=> user.login, :password => Tools::AESCrypt.new.decrypt(user.user_password))
			if @user_session.save
				redirect_to root_path
			else
			    flash[:error] = "Login Failed"
				render :action => :new, :layout => "signup"
			end
	end
		
	end
  
  def terms
  render :layout => "signup" 
  end
  
  def service_terms
  render :layout => "signup" 
  end

  def edit
	SpiceWorksController.new.do_login
  end
  
	def services
		servicess = Service.find_all_by_active(1)
		@Services ||= Array.new
		servicess.each do |service|
			if Service.find_by_service_id_and_user_id(service.id, current_user.id).blank?
				logger.info("unsubscribed service")
				@Services << service
			end
		end

		if @Services.blank?
			flash[:notice] = "There is no service activated"
			redirect_to root_path
		else
			render :layout => 'signup'
		end
	end

	def payments
		logger.info("payments................#{params.to_json}")
		if !params[:order_ids].blank?
			@orders = Order.pending_orders(current_user.id)
			@paypal_ipn_url = property(:app_site) + "/ipn/paypal/?email=" + current_user.email
			@amazon_ipn_url = property(:app_site) + "/ipn/amazon/?email=" + current_user.email
			render :layout => 'signup'
		else
			redirect_to :back
		end
	end

	def thanks
		logger.info("thanks params: #{params}")
		if !params[:auth].blank? || !params[:signature].blank?
			redirect_to user_path(current_user.id)+'/thanks'
		else
		####
		#### RAJ
		#### NOT ALWAYS TRUE. CHECK OUT CAN BE DONE LATER THAN LAST ONE
		####
=begin
				companification = Companification.find_last_by_company_id(current_user.companies[0].id) unless current_user.blank?
				unless companification.blank?
					@application = Application.find_by_id(companification.application_id)
				else
					redirect_to root_path
				end
=end

### edited by jhlee on 20120611
			if session[:application_id]!=""
				@application = Application.find_by_id(session[:application_id])
				session[:application_id] = nil
			else
				redirect_to root_path
			end
		end
	end

	def payment_thanks
		redirect_to thanks_user_path(current_user.id)
	end

	def payment_requests
		if current_user.id.to_s == params[:id]
			@user_payments = Array.new
			if params[:status] == "active" or params[:status].blank?
				@active = true
				companifications = Companification.find_all_by_company_id(current_user.companies[0].id)
				unless companifications.blank?
					payment_ids = Array.new
					companifications.each do |companification|
					 payment_ids << companification.payment_id
				end
				payments =Payment.by_payment_id(payment_ids) unless  payment_ids.blank?
				payments.each do |payment|
					payment[:subscription_end] = Companification.find_by_payment_id(payment.id).end_at
					if Payment.find_by_parent_id_and_email(payment.id, current_user.email).blank?
						@user_payments << payment 
					end
				end
			end

       #
       # payments = Payment.active_payments(current_user)
       # @user_payments ||= Array.new
       # payments.each do |payment|
       #   if Payment.find_by_parent_id_and_email(payment.id, current_user.email).blank?
       #      @user_payments << payment 
       #   end
       # end

			elsif params[:status] == "cancelled"
				cancelled_payments = Payment.cancelled_payments(current_user)
				cancelled_payments.each do  |cancelled_payment|
					payment = Payment.find_by_id(cancelled_payment.parent_id) 
					payment[:cancelled_on] = cancelled_payment.transaction_date
					@user_payments << payment
				end

			elsif  params[:status] == "refunded"
				refunded_payments = Payment.refunded_payments(current_user)
				refunded_payments.each do  |refunded_payment|
					payment = Payment.find_by_id(refunded_payment.parent_id)
					payment[:refunded_on] = refunded_payment.transaction_date
					@user_payments << payment
				end
			elsif  params[:status] == "history"
			@user_payments = Payment.find_all_by_email(current_user.email)
			end
			@user_payments = @user_payments.paginate(:page => params[:page],:per_page => 10)
		else
		redirect_to root_path
		end

	end

  def generate_user_payment_requests
   payment = Payment.find_by_id(params[:payment_id])
   application_plan = ApplicationPlan.find_by_id(payment.plan_ids)
   if application_plan.application_nature == "basic"
   user_request_fields = {:user_id=> current_user.id, :resource_type => "payments", :resource_id => params[:payment_id], :request => params[:request], :requested_at => Time.now}
   logger.info(user_request_fields)
   previous_request = UserRequest.find_by_resource_id(params[:payment_id])
   if previous_request.blank?
   @request = UserRequest.new(user_request_fields)
   #else
   #@request.request = params[:request]
   #@request.requested_at = Time.now
   #@request.status = "pending"
   end
   if @request.present? and @request.save
      if previous_request.blank?
       
       companification = Companification.find_by_company_id_and_plan_id(current_own_company.id, application_plan.id)
       employees = Employee.find_all_by_company_id(companification.company_id)
       if application_plan.code.delete(' ').downcase.include?("ippbx")
            PortalIppbxController.new.remove_company_ippbx(companification.company_id)
       elsif application_plan.code.delete(' ').downcase.include?("cloud")
	    PortalCloudstorageController.new.remove_company(companification.company_id)
       end
       
       ##cancel all addons
   
       employees.each do  |emp|
          employee_app = EmployeeApplication.find_by_employee_id_and_application_id(emp.id,companification.application_id)
          employee_app.destroy unless employee_app.blank?
	  User.find_by_id(emp.user_id).update_attributes(:phone => "") if application_plan.code.delete(' ').downcase.include?("ippbx")
       end
        Order.find_by_id(companification.order_id).update_attributes(:status => "cancelled")
	addon_companifications = Companification.find_all_by_company_id_and_application_id(companification.company_id, companification.application_id)
			addon_companifications.each do  |addon_companification|
			if !companification.plan_id == addon_companification.plan_id
				addon_fileds = {:user_id=> current_user.id, :resource_type => "payments", :resource_id => addon_companification.payment_id, :request => params[:request], :requested_at => Time.now}
				addon_request = UserRequest.new(addon_fileds)
				addon_request.save
			end
			addon_companification.destroy
	end
	
        #companification.destroy
     end
    flash[:notice] = t("views.notices.payment_request_success")
   else
     flash[:notice] = t("views.notices.payment_request_failed")
   end
    redirect_to payment_requests_user_path
   else
   do_addons application_plan,  params[:request]
   end
  end
  
  
  def do_addons add_on, request
        addon_companification = Companification.find_by_company_id_and_plan_id(current_own_company.id, addon.id)
	unless addon_companification.blank?
	previous_request = UserRequest.find_by_resource_id_and_status(addon_companification.payment_id, "status")
	if previous_request.blank?
	addon_fileds = {:user_id=> current_user.id, :resource_type => "payments", :resource_id => addon_companification.payment_id, :request => request, :requested_at => Time.now}
	addon_request = UserRequest.new(addon_fileds)
	    if addon_request.save
	     addon_companification.destroy	
	     flash[:notice] = t("views.notices.payment_request_success")
	    else
	     flash[:notice] = t("views.notices.payment_request_failed")                                                      
	    end     
	                                                              
	end
	end
	redirect_to payment_requests_user_path
  end

  
  def update
		if !params[:user][:site].blank? # Adding http:// by default
			if !params[:user][:site].starts_with?'http://'
				params[:user][:site] = "http://" + params[:user][:site]
			end
		end

=begin
		if property(:use_ippbx)
			if @user.user_has_ippbx? @user
				if !edit_ippbx_employee(params[:user], @user)
					flash[:error] = t("controllers.account_update_failed")
					render :action => :edit and return
				end
			end
		end
=end

    social_urls = Array.new 
    social_urls = validate_social_url("", "", params[:user][:linkedin] )
    params[:user][:linkedin] = social_urls[2]

		if @user.update_attributes(params[:user])
			flash[:notice] = t("controllers.account_updated")
			redirect_to :action => :show
		else
			flash[:error] = t("controllers.account_update_failed")
			render :action => :edit
		end

	end

  def show
    #@recently_users = User.public.all(:limit => 5, :order => "created_at DESC")
    @companies = @user.employers.active_employers.by_public_and_employers(current_user)
    @employees = []
    if @user == current_user
      companies = current_user.employers.active_employers.by_public_and_employers(current_user)
      companies.each do |company|
        @employees += company.active_employees.all(:order => 'created_at DESC', :limit => 20)
      end

      @employees = @employees.sort {|x,y| y[:created_at] <=> x[:created_at] }
      @employees = @employees[0..20]
    else
      @recently_users = User.public_and_coworkers(current_user).all(:order => "created_at DESC", :limit => 4)
    end
    #@companies = @user.companies.by_public_and_employers(current_user).all :order => "companies.created_at DESC", :limit => 6
    #    @employers = @user.employers.by_public_and_employers(current_user).without_own_companies(@user.id).all :limit => 6, :order => "companies.created_at DESC"
    #    count_companies = @companies.size
    #    count_employers = @employers.size
    #    if count_companies < 3
    #      @employers = @employers[0..6-count_companies]
    #    elsif count_employers < 3
    #      @companies = @companies[0..6-count_employers]
    #    else
    #      @companies = @companies[0..3]
    #      @employers = @employers[0..3]
    #    end
    
     #http://<host:port>/provisioning/voip/v1/user/callcontrol/voicemailrecord/new 

		if property(:use_ippbx)
			@vm ||= Array.new
			employee = @user.employees[0]
			unless employee.blank?
				@user_cred = Ippbx.find_by_admin_type_and_employee_id("user",employee.id.to_s)
				unless @user_cred.blank?
					user_login = @user_cred.login
					user_password = Tools::AESCrypt.new.decrypt(@user_cred.password)
					response = IppbxApi.ippbx_get(user_login, user_password, 'vm', '/voicemailrecord/', 'new')
					if response.code == '200'
						logger.info "-================------#{response.body}"
						@vm = ActiveSupport::JSON.decode(response.body)      
					end
				end
			end
		end
	end

  #TRAC 202 - Controllers - Users_Controllers - Contacts
  #
  # Added a conditional for finding out a user's coworkers.
  def contacts
    @contacts = Employee.by_company_id(params[:company_id]).by_search(params[:search]).by_contacts(current_user).paginate :page => params[:page]
    @active_employers = current_user.employers.active_employers.all
  end


  def friends
    @friends = @user.friends.paginate :page => params[:page]
  end

  def friendship_request
    if current_user.reject_friend?(@friend)
      friendship = current_user.friendships.by_friend_id(@friend.id).first
      friendship.delete_reject_friendships
    end
    success = Friendship.create_friendship current_user, @friend
    if success
      flash[:notice] = t("controllers.friendship_request_sent")
    else
      flash[:error] = t("controllers.error_send_friendship_reqeust")
    end
    redirect_to user_path(@friend)
  end

  def friendship_delete
	success = false
        friendship = current_user.friendships.by_friend_id(@friend.id).first
	if !friendship.blank?
		if friendship.friendship_id != 0
			logger.info("Acceptor Delete.............")
                        success =  friendship.friend_relationship.destroy
			
		else
			success = friendship.destroy
		end
	end
	  
	if success
		flash[:notice] = t("controllers.friendship_successful_remove")
	else
		flash[:error] = t("controllers.error_remove_friendship")
	end
	redirect_to :back
    #if !friendship.blank? && friendship.destroy
    #  flash[:notice] = t("controllers.friendship_successful_remove")
    #else
    #  flash[:error] = t("controllers.error_remove_friendship")
    #end
    #redirect_to :back
  end

  def remove_mt_association
    if @user.remove_mobile_tribe_association
      flash[:notice] = t("controllers.association_removed")
      redirect_to root_path
    else
      render :action => :edit
    end
  end

  protected
  def find_user
    if (@user = User.find_by_id params[:id]).blank?
      flash[:error] = t("controllers.cant_find_user")
      redirect_to root_path
    end
  end

  #TRAC 195 - Controllers - Users_Controller - Company_Pending
  #
  # Will redirect a user if thye try to get into an employee that is marked as 
  # 'company pending'

	def company_pending
		if (!User.find_by_id_and_company_pending(params[:id], 1).blank?)
			flash[:error] = t("controllers.user_dont_touch")
			redirect_to root_url
		end
	end

  def only_allowed_user
    report_maflormed_data(t("controllers.access_denied")) unless current_user.can_view_user_profile?(@user)
  end

  def find_friend
    @friend = User.find_by_id params[:friend_id]
    report_maflormed_data if @friend.blank?
  end

  def only_owner
    report_maflormed_data unless @user == current_user
  end
  
  def calculate_string_to_sign_v2(args)
  
   
    parameters = args[:parameters]

    uri = args[:uri] 
    uri = "/" if uri.nil? or uri.blank?
    uri = urlencode(uri).gsub("%2F", "/") 

    verb = args[:verb]
    host = args[:host].downcase


    # exclude any existing Signature parameter from the canonical string
    sorted = (parameters.reject { |k, v| k == SIGNATURE_KEYNAME }).sort
    
    canonical = "#{verb}\n#{host}\n#{uri}\n"
    isFirst = true

    sorted.each { |v|
      if(isFirst) then
        isFirst = false
      else
        canonical << '&'
      end

      canonical << urlencode(v[0])
      unless(v[1].nil?) then
        canonical << '='
        canonical << urlencode(v[1])
      end
    }

    return canonical
  end

def urlencode(plaintext)
    CGI.escape(plaintext.to_s).gsub("+", "%20").gsub("%7E", "~")
  end

#  def check_mobile_tribe_user
#    unless params[:user].blank?
#      params[:user][:mobile_tribe_login] = params[:user][:mobile_tribe_password] = "" if User::MobileTribeUserState::NOT_NEED == params[:user][:mobile_tribe_user_state].to_i
#    end
#  end

	def validate_social_url(*options)
		#facebook = http://www.facebook.com/otogo, twitter = http://www.twitter.com/otogo , linkedin = http://www.linkedin.com/company/2679523
		facebook_url, twitter_url, linkedin_url = ""
		i = 0
		options.each do |option|
			unless option.blank?

=begin
				if option !~ %r{\Ahttps?:\/\/www\.\w}i
					option = "http://www." + option
				elsif option !~ %r{\Ahttps?:\/\/\w}i
					option = "http://" + option
				end
=end
				unless option =~ %r{\Ahttps?:\/\/\w}i
					option = "http://" + option
				end

				if (option =~  %r{\Ahttps?:\/\/www.facebook.com\/\w}i) and i == 0
					facebook_url = option
				elsif (option =~  %r{\Ahttps?:\/\/www.twitter.com\/\w}i) and i == 1
					twitter_url = option 
				elsif (option =~ %r{\Ahttps?:\/\/www.linkedin.com\/\w}i)  and i ==2
					linkedin_url = option
				end
			end
			i = i+1
		end
		logger.info("linkedin_url #{linkedin_url}")

		return facebook_url, twitter_url,linkedin_url
	end
	
	private

	def create_linkedin_company(member_id, _user)
		client = LinkedIn::Client.new(property(:linkedin_api_key), property(:linkedin_secret_key))
		client.authorize_from_access(property(:linkedin_oauth_user_token), property(:linkedin_oauth_user_secret))
		token_user = client.profile(:id => member_id,:fields => %w(id api-standard-profile-request)).to_hash
		logger.info(token_user)
		logger.info(token_user["api_standard_profile_request"]["headers"]["all"])
		token_value = ""
		unless token_user["api_standard_profile_request"].blank?
		   unless token_user["api_standard_profile_request"]["headers"].blank?
		    unless token_user["api_standard_profile_request"]["headers"]["all"].blank?
			    token = token_user["api_standard_profile_request"]["headers"]["all"][0]
				if token.name == "x-li-auth-token"
				token_value = token.value
				end
			end
		   end
		end
		
		unless token_value.blank?
			default_header = {"x-li-format" => "json"}
			temp_header = {"x-li-format" => "json", "x-li-auth-token" => token_value}
			LinkedIn::Helpers::Request.const_set("DEFAULT_HEADERS", temp_header)
			user = client.profile(:id => member_id,:fields => %w(id first-name last-name positions)).to_hash
			logger.info("Users>>>>>>>>>>")
			logger.info(user)
			LinkedIn::Helpers::Request.const_set("DEFAULT_HEADERS", default_header)
			logger.info(user["positions"]["total"])
			logger.info(user["id"])
			linkedin_company_name = ""
			job_title = ""
			if user["positions"]["total"].to_i >0
			 user["positions"]["all"].each do |position|
			 if position.is_current.to_s == "true" and position.title.downcase.gsub(" ", "") == "founder"
				linkedin_company_name = position.company.name
				logger.info("Company Name>>>>>>>>>>>>>#{linkedin_company_name}")
				job_title = position.title
				break
			 end
			end
			end
			
			linkedin_company = LinkedinCompany.find_by_name(linkedin_company_name.strip)
			if linkedin_company.blank?
				linkedin_comp = get_company_fields(linkedin_company_name)
			else
				linkedin_comp = linkedin_company 
			end
			unless linkedin_comp.blank?
			   company = {:name => linkedin_company[:name], :address => linkedin_company[:address],:address2 => linkedin_company[:address2], 
						  :state => linkedin_company[:state], :zipcode => linkedin_company[:zipcode], :country => linkedin_company[:country],
						  :city => linkedin_company[:city], :phone => linkedin_company[:phone], :company_phone => linkedin_company[:company_phone],
						  :company_type => linkedin_company[:company_type], :industry => linkedin_company[:industry], :description => linkedin_company[:description],
						  :size => linkedin_company[:size], :team => linkedin_company[:team], :country_phone_code => linkedin_company[:country_phone_code],
						  :size => linkedin_company[:size], :team => linkedin_company[:team], :country_phone_code => linkedin_company[:country_phone_code],
						  :website => linkedin_company[:website], :domain_name => linkedin_company[:domain_name], :twitter => linkedin_company[:twitter],
						  :linkedin => linkedin_company[:linkedin], :facebook => linkedin_company[:facebook]
					   }
			   create_company_employee(company, _user, job_title, linkedin_comp)
			end
		end
	
	end
	
	def create_company_employee(company, user, job_title, linkedin_company)
		 phone_number = company[:phone].gsub(/0/x,"")
         phone_number= phone_number.gsub(" ","")
		 company[:company_phone] =company[:country_phone_code]+phone_number
		 if !company[:website].blank? # Adding http:// by default
			 if !company[:website].starts_with?'http://'
			 company[:website] = "http://" + company[:website]
			 end
		 end
		@company = Company.new(company)
		@company.user_id = user.id 
		employee = {:user_id => user.id,:status=> Employee::Status::ACTIVE, :company_email=> user.login + "@#{property(:sogo_email_domain)}",
			       :job_title => job_title, :phone => @company.phone
				   }

		@employee = @company.employees.build(employee)
		success = @employee.valid?
		success &= @company.save
		if success && @company.errors.empty?
		 linkedin_company.update_attributes(:is_mobiletribe_connect => 1)
		end
	end


def get_company_fields(name)
    unless name.blank?
		client = LinkedIn::Client.new(property(:linkedin_api_key), property(:linkedin_secret_key))
		client.authorize_from_access(property(:linkedin_oauth_user_token), property(:linkedin_oauth_user_secret))
    company =client.search({:keywords => name,:fields => %w(companies:(id name universal-name website-url industries logo-url employee-count-range locations:(address:(street1 city state postal-code country-code) contact-info:(phone1))))}, 'company').to_hash
    company = company["companies"]["all"][0]
	logger.info(company)
				unless company.blank?
					code, emplyee_count, employee_size, address, city, state, zipcode, phone, country = ""

					if company["industries"].present? and company["industries"]["total"].to_i > 0
						code = company["industries"]["all"][0].code
					end

					if (company["employee_count_range"].present?)
						employee_count = company["employee_count_range"]["code"]
						employee_size = company["employee_count_range"]["name"]
					end

					if (employee_count == "A" or employee_count == "B" or employee_count == "C" or employee_count == "D")
						if company["locations"]["total"].to_i>0
							address = company["locations"]["all"][0].address.street1
							city =company["locations"]["all"][0].address.city 
							state =company["locations"]["all"][0].address.state
							zipcode = company["locations"]["all"][0].address.postal_code
							phone = company["locations"]["all"][0].contact_info.phone1
							unless (company["locations"]["all"][0].address.country_code.blank?)
								country = from_country_code(company["locations"]["all"][0].address.country_code.upcase)
								company_name = company["name"]
								country_code = company["locations"]["all"][0].address.country_code.upcase
								logger.info("company name: #{company_name} country code: #{country_code}")
							end
						end

						field_company = {:name => company["name"], :address => address, :city => city, :state => state, :zipcode => zipcode, :phone => phone, :country => country, :industry =>code, :created_from => "linkedin" , :size => employee_size, :company_id => company["id"]}

						logger.info("Company ID linkedin_companies insertion #{field_company[:company_id].to_s}")

						cquery1 = "insert into linkedin_companies (created_at,linkedin,"
						cquery2 = ") values ('#{Time.new.strftime("%Y-%m-%d %H:%M:%S")}','#{field_company[:company_id]}',"
						field_company.each do |key, value| 
							unless key.blank?
								unless key.to_s.eql?("company_id")
									cquery1+= "#{key},"
									cquery2+= "'#{addslash(value.to_s)}',"
								end
							end
						end
						cquery = cquery1.chop + cquery2.chop + ")"
						logger.info(cquery)
						ActiveRecord::Base.connection.execute(cquery)

					end # of of if size filter
				end # end of unless
			link_comp = LinkedinCompany.find_by_name(name.strip)	
			return link_comp
	else
		return nil
	end
		
	end

end
