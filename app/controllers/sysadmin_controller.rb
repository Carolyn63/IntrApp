class SysadminController < ApplicationController
  def index
	 if session[:sys_admin].blank?
		#logger.info "session: #{session[sys_user]}"
		redirect_to sysadmin_logins_path
	 else
		 redirect_to sysadmin_serviceproviders_path
	 end
  end

end
