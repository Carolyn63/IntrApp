class Sysadmin::RoutingactionsController < Sysadmin::ResourcesController

	def index
=begin
		response = IppbxApi.ippbx_get('sys', 'routingactions/', 'all')
		if response.code == '200'
			@routingaction = ActiveSupport::JSON.decode(response.body)
			flash.now[:warning]  = t("controllers.get.empty.routingaction") if @routingaction.blank?
		else
			flash[:error]  = t("controllers.get.error.routingaction") + "<br />" + response.body
		end
		@routingaction ||= ''
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
			content_json = {"name" => params[:routingaction][:name],"treatment" => params[:routingaction][:treatment],"type" => params[:routingaction][:type]}.to_json
			response = IppbxApi.ippbx_post(session[:sys_admin], session[:sys_pass],'sys', 'routingaction', content_json)
			if response.code == '200'
				flash[:notice]  = t("controllers.create.ok.routingaction")
				redirect_to  sysadmin_routingactions_path
			else
				flash[:error]  = t("controllers.create.error.routingaction") + "<br />" + response.body
				render :action => 'new'
			end
    end
  end


  def destroy
    if !params[:id].blank?
      response = IppbxApi.ippbx_delete(session[:sys_admin], session[:sys_pass],'sys', 'routingaction/', params[:id])
      if response.code == '200'
				flash[:notice]  = t("controllers.delete.ok.routingaction")
      else
				flash[:error]  = t("controllers.delete.error.routingaction") + "<br />" + response.body
      end
    end
    redirect_to  sysadmin_routingactions_path
  end

end
