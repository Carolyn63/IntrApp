class RegConfirmController < ActionController::Base
  def index
    token =   params[:token]    
    unless token.blank?
      user = User.find_by_persistence_token(token)
      #active user status to active user
      user.status = 0
      user.save
      #user = User.find_by_sql("select login, password from users where persistence_token = " + token)
      logger.info "confirmed username #{user.login}"      
      logger.info "confirmed password#{Tools::AESCrypt.new.decrypt(user.user_password.to_s)}"
      @user_session = UserSession.new(:login => user.login.to_s, :password => Tools::AESCrypt.new.decrypt(user.user_password.to_s), :remember_me => false)           
      @user_session.save do |result|
        if result
          flash[:notice] = t("controllers.login_successful")          
          redirect_to new_user_company_path(user)
          user = User.find_by_username_or_email(@user_session.login)
          flash[:notice] = "Thank you. You have successfully actived your account."
          user.deliver_welcome!
        else
          flash.now[:error] = t("controllers.login_failed")
          render :action => :new
        end
      end      
    end
  end

end
