class Useradmin::LoginresourcesController < ApplicationController
  inherit_resources

  layout "login"

  before_filter :require_user

  #before_filter :admin_only
end
