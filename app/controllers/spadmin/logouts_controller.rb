class Spadmin::LogoutsController < Spadmin::ResourcesController
  def index
    session[:sp_admin] = nil
    session[:sp_pass] = nil
    flash[:notice] = t("controllers.logout.ok")
    redirect_to spadmin_logins_path    
  end

end
