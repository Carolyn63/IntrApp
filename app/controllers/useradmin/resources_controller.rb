class Useradmin::ResourcesController < ApplicationController
  inherit_resources

  layout "useradmin"

  before_filter :require_user
  #before_filter :admin_only
  before_filter :user_admin_login_required

end
