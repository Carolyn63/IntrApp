class Sysadmin::LoginsController < Sysadmin::LoginresourcesController

	def index
	end

	def create
    @host = property(:ippbx_server_ip)
    @port = property(:ippbx_server_port)
		@user = params[:do_login][:username]
		@pass = params[:do_login][:password]    
		@url = '/provisioning/voip/v1/system/admin/profile'
				
		req = Net::HTTP::Get.new(@url, initheader = {'Content-Type' =>'application/json'})
		req.basic_auth @user, @pass
		response = Net::HTTP.new(@host, @port).start {|http| http.request(req) } 

		if response.code == '200'
			flash[:notice] = t("controllers.login.ok")
			#session ||= {}
			session[:sys_admin] = @user
			session[:sys_pass] = @pass
			#logger.info "session sys_user #{session[:sys_admin]}"
			#logger.info "session sys_pass #{session[:sys_pass]}"
			redirect_to session[:sys_return_to] ||= sysadmin_adminprofiles_path
		else 
			flash[:error] = t("controllers.login.error") + "<br />" + response.body
			redirect_to sysadmin_logins_path
		end

	end

end
