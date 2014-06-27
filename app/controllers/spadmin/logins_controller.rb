class Spadmin::LoginsController < Spadmin::LoginresourcesController
  def index
    
    if !current_user.blank? and current_user.admin?
      auto_login
    end

  end
  
 	def auto_login
	  logger.info("auto login >>>>>>>>>>>>>>>>>>")
		serviceprovider =  Ippbx.find_by_name_and_admin_type(property(:serviceProvider),"serviceprovider")
	        if !serviceprovider.blank?
		      @user = serviceprovider.login
		      @pass = Tools::AESCrypt.new.decrypt(serviceprovider.password)

		      @host = property(:ippbx_server_ip)
		      @port = property(:ippbx_server_port)
		      @ippbx_url = '/provisioning/voip/v1/serviceprovider/admin/profile'

		      req = Net::HTTP::Get.new(@ippbx_url, initheader = {'Content-Type' =>'application/json'})
		      req.basic_auth @user, @pass
		      response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
		      @profile = ActiveSupport::JSON.decode(response.body)

		      #flash = {}
		      #session = {}

		      if response.code == '200'
			      session[:sp_admin] = @user
                              session[:sp_pass] = @pass
			      redirect_to spadmin_adminprofiles_path
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
			      redirect_to spadmin_logins_path
		      end
		end
	end

  def create
    @host = property(:ippbx_server_ip)
    @port = property(:ippbx_server_port)
    @user = params[:do_login][:username]
    @pass = params[:do_login][:password]
    @url = '/provisioning/voip/v1/serviceprovider/admin/profile'
    logger.info"New api caLL#{@user+@pass}"
    req = Net::HTTP::Get.new(@url, initheader = {'Content-Type' =>'application/json'})
    req.basic_auth @user, @pass
    response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }

    if response.code == '200'
      flash[:notice] = t("controllers.login.ok")
      session[:sp_admin] = @user
      session[:sp_pass] = @pass
      cookies[:id] = "rubyer.me"
      # cookies[:user_preference] = {
        # :value => "my boy",
        # :expires => 2.weeks.from_now.utc
      # }
    redirect_to session[:sp_return_to] ||= spadmin_adminprofiles_path
    else
      begin
        temp_res_code = "[" + response.body.split(",")[0].split(":")[1].strip + "]" 
        temp_res_err_msg = response.body.split(",")[1].split(":", 2)[1].strip
        temp_res_err_type = response.body.split(",")[2].split(":", 2)[1].strip
        response.body[0..-1] = temp_res_err_type[1..temp_res_err_type.rindex('"')-1] +" "+ temp_res_err_msg[1..temp_res_err_msg.rindex('"')-1] +" "+ temp_res_code
      rescue
      end
    flash[:error] = t("controllers.login.error") + "<br />" + response.body
    redirect_to spadmin_logins_path
    end

  end
end
