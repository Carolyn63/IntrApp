class Sysadmin::GatewaygroupsController < Sysadmin::ResourcesController

	def index
=begin
		response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'gatewaygroups/', 'all')
		if response.code == '200'
			@gatewaygroup = ActiveSupport::JSON.decode(response.body)
			flash.now[:warning]  = t("controllers.get.empty.gatewaygroup") if @gatewaygroup.blank?
		else
			flash[:error]  = t("controllers.get.error.gatewaygroup") + "<br />" + response.body
		end
		@gatewaygroup ||= ''
=end
	end

  def new
  end

  def create
    action = params[:commit].downcase
    case action
    when "cancel"
      redirect_to :action => :index
    else
			content_json = {"name" => params[:gatewaygroup][:name],"treatment" => params[:gatewaygroup][:treatment],"type" => params[:gatewaygroup][:type]}.to_json
			response = IppbxApi.ippbx_post(session[:sys_admin], session[:sys_pass],'sys', 'gatewaygroup', content_json)
			if response.code == '200'
				flash[:notice]  = t("controllers.create.ok.gatewaygroup")
				redirect_to  sysadmin_gatewaygroups_path
			else
				flash[:error]  = t("controllers.create.error.gatewaygroup") + "<br />" + response.body
				render :action => 'new'
			end
    end
  end


  def destroy
    if !params[:id].blank?
      response = IppbxApi.ippbx_delete(session[:sys_admin], session[:sys_pass],'sys', 'gatewaygroup/', params[:id])
      if response.code == '200'
				flash[:notice]  = t("controllers.delete.ok.gatewaygroup")
      else
				flash[:error]  = t("controllers.delete.error.gatewaygroup") + "<br />" + response.body
      end
    end
    redirect_to  sysadmin_gatewaygroups_path
  end

end
