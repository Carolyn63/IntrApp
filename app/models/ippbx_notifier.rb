class IppbxNotifier < ActionMailer::Base

  def welcome_sp_admin(loginName, password, emailId)
    setup
    subject       "Welcome to Ippbx Service Provider Admin"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName, :password => password, :website_url => URI.escape(property(:app_site)) + spadmin_logins_path
    logger.info "Sending an email to #{emailId}, creating service provider admin succesfully"
  end

  def welcome_ent_admin(loginName, password, emailId)
    setup
    subject       "Welcome to Ippbx Enterprise Admin"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName, :password => password, :website_url => URI.escape(property(:app_site)) + entadmin_logins_path
    logger.info "Sending an email to #{emailId}, creating enterprise admin succesfully"
  end

  def welcome_user_admin(loginName, password, emailId)
    setup
    subject       "Welcome to Ippbx User Admin"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName, :password => password, :website_url => URI.escape(property(:app_site)) + useradmin_logins_path
    logger.info "Sending an email to #{emailId}, creating user admin succesfully"
  end

  def sys_admin_self_password_reset(loginName, password, emailId)
    setup
    subject       "Ippbx System Admin Password Self Reset"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName, :password => password, :website_url => URI.escape(property(:app_site)) + sysadmin_logins_path
    logger.info "Sending an email to #{emailId}, changed system admin password succesfully"
  end

  def sp_admin_self_password_reset(loginName, password, emailId)
    setup
    subject       "Ippbx Service Provider Admin Password Self Reset"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName, :password => password, :website_url => URI.escape(property(:app_site)) + spadmin_logins_path
    logger.info "Sending an email to #{emailId}, changed service provider admin password succesfully"
  end

  def ent_admin_self_password_reset(loginName, password, emailId)
    setup
    subject       "Ippbx Enterprise Admin Password Self Reset"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName, :password => password, :website_url => URI.escape(property(:app_site)) + entadmin_logins_path
    logger.info "Sending an email to #{emailId}, changed enterprise admin password succesfully"
  end

  def user_admin_self_password_reset(loginName, password, emailId)
    setup
    subject       "Ippbx User Admin Password Self Reset"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName, :password => password, :website_url => URI.escape(property(:app_site)) + useradmin_logins_path
    logger.info "Sending an email to #{emailId}, changed user admin password succesfully"
  end

  def sp_admin_delete(loginName, emailId)
    setup
    subject       "Ippbx " + loginName.to_s.titleize + " Service Provider Admin Is Deleted"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName
    logger.info "Sending an email to #{emailId}, service provider admin is deleted"
  end

  def ent_admin_delete(loginName, emailId)
    setup
    subject       "Ippbx " + loginName.to_s.titleize + " Enterprise Admin Is Deleted"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName
    logger.info "Sending an email to #{emailId}, enterprise admin is deleted"
  end

  def user_admin_delete(loginName,emailId)
    setup
    subject       "Ippbx " + loginName.to_s.titleize + " User Admin Is Deleted"
    recipients    emailId
    content_type "text/html"
    body :loginName => loginName
    logger.info "Sending an email to #{emailId}, user admin is deleted"
  end
  protected

  def setup
    from          property(:email_from)
    sent_on       Time.now
  end

end
