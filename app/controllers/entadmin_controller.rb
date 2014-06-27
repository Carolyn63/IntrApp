class EntadminController < ApplicationController
  def index
 if session[:portal_ent_id].blank?
 redirect_to entadmin_logins_path
 else
   redirect_to entadmin_users_path
 end

  
  end

end
