class Spadmin::ResourcesController < ApplicationController
  inherit_resources

  layout "spadmin"

  #before_filter :require_user
  #before_filter :admin_only
  before_filter :sp_admin_login_required

end
