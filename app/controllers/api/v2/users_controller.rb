class Api::V2::UsersController < ApplicationController

  def contacts
    @user = User.first
    if @user.blank?
      render :nothing => true, :status => 404
    else
      respond_to do |format|
        format.html {render :nothing => true, :status => 200}
        format.json {render :nothing => true, :status => 200}
        format.xml do
          @contacts = @user.contacts
        end
      end
    end
  end

  def friends
    @user = User.first
    if @user.blank?
      render :nothing => true, :status => 404
    else
      respond_to do |format|
        format.html {render :nothing => true, :status => 200}
        format.json {render :nothing => true, :status => 200}
        format.xml do
          @friends = @user.friends
        end
      end
    end
  end

end
