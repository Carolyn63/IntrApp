class Sysadmin::ResourcesController < ApplicationController
	inherit_resources

	layout "sysadmin"

	#before_filter :require_user
	#before_filter :admin_only

	before_filter :sys_admin_login_required

end