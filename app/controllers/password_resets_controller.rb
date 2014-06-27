class PasswordResetsController < ApplicationController
  layout "signup"
  before_filter :require_no_user
  before_filter :load_user_using_perishable_token, :only => [ :edit, :update ]

  def new
  end

  def create
    @user = User.find_by_username_or_email(params[:email])
    if @user
      @user.deliver_password_reset_instructions!
      flash[:notice] = t("controllers.instruction_reset_your_password_sent")
      redirect_to root_path
    else
      flash.now[:error] = t("controllers.no_user_was_found_for_this_login", :email => params[:email])
      render :action => :new
    end
  end

  def edit
  end

  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.active = true
    @user.company_pending = 0
    if @user.save
      flash[:notice] = t("controllers.your_password_updated")
      redirect_to root_path
    else
      render :action => :edit
    end
  end


  private

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id], 24.hours)
    unless @user
      flash[:error] = t("controllers.reset_your_password_expired")
      redirect_to root_url
    end
  end
end
