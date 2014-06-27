# cLass for handling emails aand such.
class Notifier < ActionMailer::Base
  # Email activation instructions
  def activation_instructions(user)
    setup
    subject       "oToGo Mobile: Activate your new account"
    recipients    user.email
    body          :account_activation_url => activate_url(user.perishable_token),
                  :fullname => user.name,
                  :username => user.login,
                  :site_url => property(:domain),
                  :root_url => root_url,
                  :invitation_cutoff_time => "TBD",
                  :sent_on_time => sent_on.strftime("%H:%M"),
                  :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

      
  def cloud_storage_created(user, pass, email, admin_url, user_url)
    setup
    subject       "oToGo Mobile: Your Cloud Storage Has Been Created"
    recipients    email
    body          :username=> user,
                  :password => pass,
                  :url_admin => admin_url,
                  :url_user => user_url,
                  :sent_on_time => sent_on.strftime("%H:%M"),
                  :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def confirm(user)
    setup
    subject       "oToGo Mobile: #{property(:sp_name)} portal account registration confirmation"
    recipients    user.email
    body          :user => user,
                  :fullname => user.name,
                  :profile_url => user_url(user),
                  :site_url => property(:domain),
                  :root_url => root_url,
                  :sent_on_time => sent_on.strftime("%H:%M"),
                  :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def welcome(user)
    setup
    subject       "oToGo Mobile: Your account is now activated"
    recipients    user.email
    body          :user => user,
                  :fullname => user.name,
                  :profile_url => user_url(user),
                  :site_url => property(:domain),
                  :root_url => root_url,
                  :sent_on_time => sent_on.strftime("%H:%M"),
                  :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def password_reset_instructions(user)
    setup
    subject      "oToGo Mobile: Password reset request"
    recipients   user.email
    body         :edit_password_reset_url => edit_password_reset_url(user.perishable_token),
                 :user => user,
                 :fullname => user.name,
                 :site_url => property(:domain),
                 :root_url => root_url,
                 :profile_url => user_url(user),
                 :invitation_cutoff_time => "TBD",
                 :sent_on_time => sent_on.strftime("%H:%M"),
                 :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def reject(employee)
    setup
    subject      "oToGo Mobile: Employment rejected"
    recipients    employee.user.email
    body          :employee => employee
  end

  def invite(employee)
    setup
    subject      "oToGo Mobile: Activate your new account"
    recipients   employee.user.email
    body         :employee => employee,
                 :invitation_url => invitation_url(:invitation_token => employee.invitation_token.to_s),
                 :site_url => property(:domain),
                 :root_url => root_url,
                 :sent_on_time => sent_on.strftime("%H:%M"),
                 :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def contact_us(params)
    setup
    subject      "oToGo Mobile: Support"
    recipients   "support@otogomobile.net"
    #recipients   "ghost.miha@gmail.com"
    body         :name => params[:name],
                 :email => params[:email],
                 :reason => params[:reason],
                 :description => params[:description],
                 :site_url => property(:domain),
                 :root_url => root_url,
                 :sent_on_time => sent_on.strftime("%H:%M"),
                 :sent_on_date => sent_on.strftime("%A %d %B %Y")
    unless params[:attachment].blank?
      attachment :content_type => params[:attachment].content_type.to_s,
                 :body => params[:attachment].read,
                 :filename => params[:attachment].original_filename
    end
  end

  def audit_message(emails, audit)
    setup
    subject      "oToGo Mobile: #{Audit::Statuses::TO_LIST[audit.status]} deleted of #{audit.auditable_type}"
    recipients   emails
    body         :audit => audit,
                 :site_url => property(:domain),
                 :root_url => root_url,
                 :sent_on_time => sent_on.strftime("%H:%M"),
                 :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def payment_notification(emails,id, login, plan)
    setup
    subject      "oToGo Mobile: Application #{plan.code} Activated"
    recipients   emails
    content_type "text/html"
    body         :plan =>plan,
                 :manage_payment_url => property(:app_site) + "/users/#{id}/payment_requests",
                 :application_url =>  property(:app_site) + "/users/#{id}/applications/#{plan.application_id}",
                 :login => login,
                 :sent_on_time => sent_on.strftime("%H:%M"),
                 :sent_on_date => sent_on.strftime("%A %d %B %Y")

  end

  def subscr_cancel(emails, login, item)
    setup
    subject      "oToGo Mobile: Subscription Cancelled."
    recipients   emails
    content_type "text/html"
    body         :item =>item,
                 :login => login,
                 :sent_on_time => sent_on.strftime("%H:%M"),
                 :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def application_details(emails,id, login, plan)
    setup
    subject      "oToGo Mobile: Application #{plan.code} Activated"
    recipients   emails
    content_type "text/html"
    body         :plan =>plan,
                 :application_url =>  property(:app_site) + "/users/#{id}/applications/#{plan.application_id}",
                 :login => login,
                 :sent_on_time => sent_on.strftime("%H:%M"),
                 :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end
  
  def application_download_url application, user, email, download_url
    setup
    subject      "oToGo Mobile: Download Link for application #{application.name}"
    recipients   email
    content_type "text/html"
    body         :application => application,
                 :download_url => download_url,
                 :user => user,
                 :sent_on_time => sent_on.strftime("%H:%M"),
                 :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end
  
  def application_bin_file application, user, email, file_name
    full_name = File.basename(file_name)
    logger.info(file_name)
    setup
    subject      "oToGo Mobile: Bin File for application #{application.name}"
	attachment  :body => File.read(file_name),
	            :filename => full_name.to_s
    recipients   email
    content_type "text/html"
    body         :application => application,
                 :user => user,
                 :sent_on_time => sent_on.strftime("%H:%M"),
                 :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  protected

  def setup
    content_type  "text/html"
    from          property(:email_from)
    sent_on       Time.now
  end

end
