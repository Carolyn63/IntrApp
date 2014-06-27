class Sysadmin::FeaturesController < Sysadmin::ResourcesController

	def index
		response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'features/', 'all')
		if response.code == '200'
			@features = ActiveSupport::JSON.decode(response.body)
			flash.now[:warning]  = t("controllers.get.empty.assigned_features") if @features.blank?
		else
			flash[:error]  = t("controllers.get.error.assigned_features") + "<br />" + response.body
		end
		@features ||= ''
	end

end
