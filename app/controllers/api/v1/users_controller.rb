class Api::V1::UsersController < ApplicationController
  before_filter :require_user

  def contacts
    @user = User.find_by_login params[:id]
    if @user.blank?
      render :nothing => true, :status => 404
    else
      respond_to do |format|
        format.html {}
        format.json {}
        format.xml do
          @contacts = @user.contacts
        end
      end
    end
  end

  def friends
    @user = User.find_by_login params[:id]
    if @user.blank?
      render :nothing => true, :status => 404
    else
      respond_to do |format|
        format.html {}
        format.json {}
        format.xml do
          @friends = @user.friends
        end
      end
    end
  end

  protected
#  def login_api
#    authenticate_or_request_with_http_basic do |login, password|
#      user = UserSession.new(login, password)
#      user.save do |result|
#        if result
#          self.current_user = user
#        else
#          redirect_to :status => 403
#        end
#      end
#    end
#  end

end
