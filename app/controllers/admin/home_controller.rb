class Admin::HomeController < ApplicationController
  before_filter :require_user
  before_filter :admin_only

  def index
    
  end
  
end
