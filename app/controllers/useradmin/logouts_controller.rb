class Useradmin::LogoutsController < ApplicationController
  def index
    session[:user_admin] = nil
    session[:user_pass] = nil
    session[:user_admin_id] = nil
    flash[:notice] = t("controllers.logout.ok")
    redirect_to user_path(current_user.id)
  end
end
