class Sysadmin::PromptsController < Sysadmin::ResourcesController
	def index
=begin
		response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'prompts/', 'all')
		if response.code == '200'
			@prompts = ActiveSupport::JSON.decode(response.body)
			flash.now[:warning]  = t("controllers.get.empty.prompts") if @prompts.blank?
		else
			flash[:error]  = t("controllers.get.error.prompts") + "<br />" + response.body
		end
		@prompts ||= ''
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
			content_json = {"name" => params[:prompts][:name],"treatment" => params[:prompts][:treatment],"type" => params[:prompts][:type]}.to_json
			response = IppbxApi.ippbx_post(session[:sys_admin], session[:sys_pass],'sys', 'prompts', content_json)
			if response.code == '200'
				flash[:notice]  = t("controllers.create.ok.prompts")
				redirect_to  sysadmin_prompts_path
			else
				flash[:error]  = t("controllers.create.error.prompts") + "<br />" + response.body
				render :action => 'new'
			end
    end
  end


  def destroy
    if !params[:id].blank?
      response = IppbxApi.ippbx_delete(session[:sys_admin], session[:sys_pass],'sys', 'prompts/', params[:id])
      if response.code == '200'
				flash[:notice]  = t("controllers.delete.ok.prompts")
      else
				flash[:error]  = t("controllers.delete.error.prompts") + "<br />" + response.body
      end
    end
    redirect_to  sysadmin_prompts_path
  end

end
