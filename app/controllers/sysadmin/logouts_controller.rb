class Sysadmin::LogoutsController < Sysadmin::ResourcesController

	def index
		session[:sys_admin] = nil
		session[:sys_pass] = nil
		flash[:notice] = t("controllers.logout.ok")
		redirect_to sysadmin_logins_path    
	end

end
