class Entadmin::ResourcesController < ApplicationController
  inherit_resources

  layout "entadmin"

  #before_filter :require_user
  #before_filter :admin_only
  before_filter :ent_admin_login_required

end
