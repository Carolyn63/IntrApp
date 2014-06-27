class Entadmin::LogoutsController < ApplicationController
  def index
    session[:ent_admin] = nil
    session[:ent_pass] = nil
    #UI restrict that entName of ippbx and portal are the same
    session[:ent_name] = nil
    session[:ippbx_ent_id] = nil
    session[:portal_ent_id] = nil

    logger.info "========Ent Admin Logout sucessfully!========"
    logger.info "sessions are destroyed"    
    flash[:notice] = t("controllers.logout.ok")
    redirect_to entadmin_logins_path
  end

end
