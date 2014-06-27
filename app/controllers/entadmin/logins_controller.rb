class Entadmin::LoginsController < Entadmin::LoginresourcesController
   before_filter :check_company_ippbx, :only => [:index]
  
  def index

  end

  def create
    @host = property(:ippbx_server_ip)
    @port = property(:ippbx_server_port)
    @user = params[:do_login][:username]
    @pass = params[:do_login][:password]
    @url = '/provisioning/voip/v1/enterprise/profile'

    req = Net::HTTP::Get.new(@url, initheader = {'Content-Type' =>'application/json'})
    req.basic_auth @user, @pass
    response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
    response = format_http_response(response)
    if response.code == '200'
    flash[:notice] = t("controllers.login.ok")       
    @response_decode = ActiveSupport::JSON.decode(response.body)
    
    #saved session list: session[:ent_name], session[:ippbx_ent_id], session[:portal_ent_id]
    session[:ent_admin] = @user
    session[:ent_pass] = @pass    
    #UI restrict that entName of ippbx and portal are the same 
    session[:ent_name] = @response_decode["enterprise"]["name"]
    session[:ippbx_ent_id] = @response_decode["enterprise"]["uid"]        
    company= Company.find_by_name(session[:ent_name])
    session[:portal_ent_id] = company.id
    
    #output loggin info
    logger.info "========Ent Admin Login Info (Login Sucessully)========"
    logger.info "adminName: #{session[:ent_admin]}"
    logger.info "password: #{session[:ent_pass]}"
    logger.info "enterprise Name: #{session[:ent_name]}"    
    logger.info "ippbx enterprise id: #{session[:ippbx_ent_id]}"
    logger.info "portal enterprise id: #{session[:portal_ent_id]}"    
            
    redirect_to session[:ent_return_to] ||= entadmin_adminprofiles_path
    else
    
    logger.error "========Ent Admin Login Failed!========"
    logger.error "Failure reason: #{response.body}"    
          
    flash[:error] = t("controllers.login.error") + "<br />" + response.body
    redirect_to entadmin_logins_path
    end

  end

  private

  def format_http_response(res)
    response = res
    unless response.code == '200'
      begin
        temp_res_code = "[" + response.body.split(",")[0].split(":")[1].strip + "]"
        temp_res_err_msg = response.body.split(",")[1].split(":", 2)[1].strip
        temp_res_err_type = response.body.split(",")[2].split(":", 2)[1].strip
        response.body[0..-1] = temp_res_err_type[1..temp_res_err_type.rindex('"')-1] +" "+ temp_res_err_msg[1..temp_res_err_msg.rindex('"')-1] +" "+ temp_res_code
      rescue
        response = res
      end
    end
    return response
  end

end
