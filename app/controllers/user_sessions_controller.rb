class UserSessionsController < ApplicationController
	layout "signup"
	before_filter :require_no_user, :only => [:new, :create]
	before_filter :require_user, :only => :destroy

	rescue_from ActionController::InvalidAuthenticityToken do
		reset_session
		redirect_to(root_path)
	end 


=begin
	def new
		session[:member_id] = nil
		session[:first_name] = nil
		session[:last_name] = nil
		session[:linkedin_merge] = nil
		@user_session = UserSession.new
		session_domain = property(:session_domain)
		logger.info "session_domain: #{session_domain}"
		if(property(:use_sogo))
			unless cookies["sogo_logout"].blank?
				@sogo_email = cookies["sogo_logout"]
				cookies.delete("sogo_logout", "domain" => session_domain)
			end
		end

		if params[:oauth_token].present? and params[:oauth_verifier].present?
			#http://community.spiceworks.com/user/profile_data?format=xml

			logger.info(session[:request_token].authorize_url)
			# session[:request_token].authorize_url = http://community.spiceworks.com/oauth/authorize?oauth_token=azI6jKaP9plEr5D8Xn2A
			# is not correct

			@access_token=session[:request_token].get_access_token(:oauth_verifier => params[:oauth_verifier])
			logger.info(@access_token.to_json)
			resoponse = @access_token.get "/user/profile_data?format=json"
			logger.info(response.class)
			logger.info("response: #{response.body.to_json}")
			logger.info("Response Body #{response.body[0]}")
			logger.info("Response Body #{response.body.class.to_json}")
			logger.info("Response Code #{response.status}")
			rsp = JSON.parse(response.body[0])
			logger.info(rsp)
		end
	end
=end
	def new
		session[:member_id] = nil
		session[:first_name] = nil
		session[:last_name] = nil
		session[:linkedin_merge] = nil
		@user_session = UserSession.new
		session_domain = property(:session_domain)
		logger.info "session_domain: #{session_domain}"
		if(property(:use_sogo))
			unless cookies["sogo_logout"].blank?
				@sogo_email = cookies["sogo_logout"]
				cookies.delete("sogo_logout", "domain" => session_domain)
			end
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
	end

	def spiceworks
		@consumer=OAuth::Consumer.new property(:spiceworks_consumer_key), 
                              property(:spiceworks_consumer_secret_key), 
                              {:site=>"http://community.spiceworks.com"}

		@request_token=@consumer.get_request_token(:oauth_callback => property(:app_site)+"/login")

		# session[:request_token].authorize_url has to be changed #jhlee
		session[:request_token] = @request_token

		logger.info("request URL... #{@request_token.authorize_url}")
		@redirection_url = @request_token.authorize_url 
		@redirection_url = @redirection_url.sub("oauth", "public_oauth")

		@redirection_url = URI::escape(@redirection_url)
		
		logger.info("@redirection_url:  #{@redirection_url}")
		render :partial => "spiceworks"
	end
	
	def create
		params[:user_session] = remove_space(params[:user_session])
		@user_session = UserSession.new
		unless session[:linkedin_signin] or session[:spice_lname]
		    logger.info("Normal Login>>>>>>>>>>>>>>")
			@user_session = UserSession.new(params[:user_session])
		else
		    logger.info("User 3p>>>>>>>>>>>>>>>>>")
			session[:member_id] = params[:memberid]
		    user3p = User3p.find_by_member_id(params[:memberid])
			unless user3p.blank?
			logger.info("User3p ID#{user3p.id}")
			user = User.find_by_id(user3p.user_id)
			unless user.blank?
			@user_session = UserSession.new(:login=> user.login, :password => Tools::AESCrypt.new.decrypt(user.user_password))
			end
     		end
		end
			@user_session.save do |result|
				if result
                    session[:member_id] = nil
					flash[:notice] = t("controllers.login_successful")
					redirect_back_or_default root_path
					user = User.find_by_username_or_email(@user_session.login)
				else
				    if session[:linkedin_signin] or session[:spice_lname]#merge options
							session[:first_name] = params[:first_name]
							session[:last_name] = params[:last_name]
							session[:member_id] = params[:memberid]
							session[:linkedin_merge] = "true"
							if session[:linkedin_signin]
							session[:network] = "linkedin"
							elsif  session[:spice_lname]
							session[:network] = "spiceworks"
							end
					        render :action => :merge
					        
					else
					flash.now[:error] = t("controllers.login_failed")
					render :action => :new
					end
				end
			end
		session[:linkedin_signin] = nil
		session[:spice_email] = nil
		session[:spice_fname] = nil
		session[:spice_lname] = nil
	end
	
	def merge
	    unless session[:member_id].blank?
		@user_session = UserSession.new
		session_domain = property(:session_domain)
		logger.info "session_domain: #{session_domain}"
		if(property(:use_sogo))
			unless cookies["sogo_logout"].blank?
				@sogo_email = cookies["sogo_logout"]
				cookies.delete("sogo_logout", "domain" => session_domain)
			end
		end
		else
	    render :action => :new
		end
	end
	
	def merge_user3p
	    unless params[:memberid].blank?
		params[:user_session] = remove_space(params[:user_session])
		@user_session = UserSession.new
	    @user_session = UserSession.new(params[:user_session])
		if params[:network] == "linkedin"
		network = "linkedin"
		profile_url = "http://www.linkedin.com/profile/view?id=#{params[:memberid]}"
        elsif params[:network] == "spiceworks"
		network = "spiceworks"
		profile_url = "http://www.spiceworks.com"
        end		

		@user_session.save do |result|
				if result
					session[:member_id] = nil
					session[:network]   = nil
					user = User.find_by_username_or_email(@user_session.login)
					@user3p = User3p.new(:member_id => params[:memberid], :user_id => user.id, :network => network, :created_at => Time.new.strftime("%Y-%m-%d %H:%M:%S"), :profile_url => profile_url)
					@user3p.save
					flash[:notice] = t("controllers.login_successful")
					redirect_back_or_default root_path
				else # added by jhlee
					flash.now[:error] = t("controllers.login_failed")
					render :action => :merge
				end
		end
		else
		render :action => :new
		end
	end
	

	def destroy
		current_user_session.destroy
		session_domain = property(:session_domain)
		if(property(:use_sogo))
			sogo_email = cookies["sogo_email"]
			cookies.delete("sogo_email", "domain" => session_domain)
			cookies.delete("mt_client_link_click", "domain" => session_domain)

			cookies["sogo_logout"] =  {
				"value" => sogo_email,
				"path" => "/",
				"expires" => Time.now + 1.minutes,
				"domain" => session_domain
			} unless sogo_email.blank?
		end

		flash[:notice] = t("controllers.logout_successful")
		redirect_to root_path
	end
	
	def do_login
	@user_id = ""
 	user3p = User3p.find_by_member_id(params[:member_id])
	unless user3p.blank?
		logger.info("User3p ID#{user3p.id}")
		user = User.find_by_id(user3p.user_id)
		unless user.blank?
			@user_session = UserSession.new(:login=> user.login, :password => Tools::AESCrypt.new.decrypt(user.user_password))
			@user_session.save do |result|
			if result
				  user = User.find_by_username_or_email(@user_session.login)
				  @user_id = user.id
			end	
			end
		end
	end	
	logger.info("Do Login>...>>>>>>")
	render :partial => "do_login"
	end


end
