class HomeController < ApplicationController
	protect_from_forgery :except => [:index]

  def index
		if !params[:signature].blank?
			return
		else
			flash[:error] = t("controllers.sogo_error") + params[:cas_error] unless params[:cas_error].blank?
			if current_user.blank?
				redirect_to login_path
			else
				#redirect_to current_user.admin? ? admin_path : user_dashboard_index_path(current_user)
				redirect_to user_dashboard_index_path(current_user)
			end
		end
    #render :status => 200, :text => "answer"
  end

end

=begin
  def index
    flash[:error] = t("controllers.sogo_error") + params[:cas_error] unless params[:cas_error].blank?
    if current_user.blank?
      redirect_to login_path
    else
      #redirect_to current_user.admin? ? admin_path : user_dashboard_index_path(current_user)
      redirect_to user_dashboard_index_path(current_user)
    end
    #render :status => 200, :text => "answer"
  end

=end
