class CloudstorageNotifier < ActionMailer::Base

	def welcome_ent_admin(adminName, loginName, password, emailId)
		setup
		subject       "Welcome to LeapDrive Company Admin"
		recipients    emailId
		content_type "text/html"
		body :adminName => adminName, :loginName => loginName, :password => password
		logger.info "Sending an email to #{emailId}, cloudstorage: creating enterprise admin succesfully"
	end

	def welcome_user_admin(userName, loginName, password, emailId)
		setup
		subject       "Welcome to LeapDrive User Admin"
		recipients    emailId
		content_type "text/html"
		body :userName => userName, :loginName => loginName, :password => password
		logger.info "Sending an email to #{emailId}, cloudstorage: creating user admin succesfully"
	end

	def ent_admin_delete(loginName, emailId)
		setup
		subject       "LeapDrive " + loginName.to_s.titleize + " Enterprise Admin Is Deleted"
		recipients    emailId
		content_type "text/html"
		body :loginName => loginName
		logger.info "Sending an email to #{emailId}, cloudstorage: enterprise admin is deleted"
	end

	def user_admin_delete(loginName,emailId)
		setup
		subject       "LeapDrive " + loginName.to_s.titleize + " User Admin Is Deleted"
		recipients    emailId
		content_type "text/html"
		body :loginName => loginName
		logger.info "Sending an email to #{emailId}, cloudstorage: user admin is deleted"
	end
	protected

	def setup
		from          property(:email_from)
		sent_on       Time.now
	end

end
