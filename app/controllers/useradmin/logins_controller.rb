class Useradmin::LoginsController < Useradmin::LoginresourcesController
        before_filter :check_user_ippbx, :only => [:index]
	
	def create
		if current_user
			   ippbx = Ippbx.find_by_employee_id_and_admin_type(current_user.employees[0].id, "user")
	
		        @user = ippbx.login
			@pass = Tools::AESCrypt.new.decrypt(current_user.user_password)
			#logger.info "@user #{@user}"
			#logger.info "@pass #{@pass}"
		else
			@user = params[:do_login][:username]
			@pass = params[:do_login][:password]
		end

		@host = property(:ippbx_server_ip)
		@port = property(:ippbx_server_port)
		@ippbx_url = '/provisioning/voip/v1/user/profile'

		req = Net::HTTP::Get.new(@ippbx_url, initheader = {'Content-Type' =>'application/json'})
		req.basic_auth @user, @pass
		response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
		@profile = ActiveSupport::JSON.decode(response.body)

		logger.info "response #{response.code}"

		if response.code == '200'
			logger.info "@profile_uid #{@profile['userTbl']['uid']}"
			flash[:notice] = t("controllers.login.ok")
			session[:user_admin] = @user
			session[:user_pass] = @pass
			session[:user_admin_id] = @profile["userTbl"]["uid"]
			redirect_to useradmin_profiles_path
		else
			begin
				temp_res_code = "[" + response.body.split(",")[0].split(":")[1].strip + "]"
				temp_res_err_msg = response.body.split(",")[1].split(":", 2)[1].strip
				temp_res_err_type = response.body.split(",")[2].split(":", 2)[1].strip        
				response.body[0..-1] = temp_res_err_type[1..temp_res_err_type.rindex('"')-1] +" "+ temp_res_err_msg[1..temp_res_err_msg.rindex('"')-1] +" "+ temp_res_code
			rescue        
			end
			flash[:error] = t("controllers.login.error") + "<br />" + response.body
			redirect_to useradmin_logins_path
		end
	end



	def index
	  if current_user
	    autologin
	  end
	end
		
	def autologin
	  logger.info("auto login >>>>>>>>>>>>>>>>>>")
	        ippbx = Ippbx.find_by_employee_id_and_admin_type(current_user.employees[0].id, "user")
	
		@user = ippbx.login
		@pass = Tools::AESCrypt.new.decrypt(current_user.user_password)

		@host = property(:ippbx_server_ip)
		@port = property(:ippbx_server_port)
		@ippbx_url = '/provisioning/voip/v1/user/profile'

		req = Net::HTTP::Get.new(@ippbx_url, initheader = {'Content-Type' =>'application/json'})
		req.basic_auth @user, @pass
		response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
		@profile = ActiveSupport::JSON.decode(response.body)

		#flash = {}
		#session = {}

		if response.code == '200'
			logger.info "@profile_uid #{@profile['userTbl']['uid']}"
			logger.info "current_user #{current_user.login}"
			flash[:notice] = t("controllers.login.ok")
			session[:user_admin] = @user
			session[:user_pass] = @pass
			session[:user_admin_id] = @profile["userTbl"]["uid"]
			session[:user_return_to] ||= useradmin_profiles_path
			logger.info("session name/.........#{session[:user_admin]}")
			logger.info("session pass........#{session[:user_pass]}")
			redirect_to useradmin_profiles_path
			#render :template => 'useradmin/profiles', :action => 'index' and return
		else
			begin
				temp_res_code = "[" + response.body.split(",")[0].split(":")[1].strip + "]"
				temp_res_err_msg = response.body.split(",")[1].split(":", 2)[1].strip
				temp_res_err_type = response.body.split(",")[2].split(":", 2)[1].strip        
				response.body[0..-1] = temp_res_err_type[1..temp_res_err_type.rindex('"')-1] +" "+ temp_res_err_msg[1..temp_res_err_msg.rindex('"')-1] +" "+ temp_res_code
			rescue        
			end
			flash[:error] = t("controllers.login.error") + "<br />" + response.body
			ippbx = Ippbx.find_by_employee_id_and_admin_type(current_user.employees[0].id, "user")
	                #redirect_to useradmin_logins_path
			redirect_to :back
		end
	end

end
