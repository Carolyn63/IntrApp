class Sysadmin::PstnsController < Sysadmin::ResourcesController

	def index
=begin
		response = IppbxApi.ippbx_get('sys', 'pstngateways/', 'all')
		if response.code == '200'
			@pstn = ActiveSupport::JSON.decode(response.body)
			flash.now[:warning]  = t("controllers.get.empty.pstn") if @pstn.blank?
		else
			flash[:error]  = t("controllers.get.error.pstn") + "<br />" + response.body
		end
		@pstn ||= ''
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
			content_json = {"name" => params[:pstn][:name],"treatment" => params[:pstn][:treatment],"type" => params[:pstn][:type]}.to_json
			response = IppbxApi.ippbx_post(session[:sys_admin], session[:sys_pass],'sys', 'pstngateway', content_json)
			if response.code == '200'
				flash[:notice]  = t("controllers.create.ok.pstn")
				redirect_to  sysadmin_pstns_path
			else
				flash[:error]  = t("controllers.create.error.pstn") + "<br />" + response.body
				render :action => 'new'
			end
    end
  end


  def destroy
    if !params[:id].blank?
      response = IppbxApi.ippbx_delete(session[:sys_admin], session[:sys_pass],'sys', 'pstngateway/', params[:id])
      if response.code == '200'
				flash[:notice]  = t("controllers.delete.ok.pstn")
      else
				flash[:error]  = t("controllers.delete.error.pstn") + "<br />" + response.body
      end
    end
    redirect_to  sysadmin_pstns_path
  end

end
