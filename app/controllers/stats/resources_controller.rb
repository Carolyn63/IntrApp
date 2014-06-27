class Stats::ResourcesController < ApplicationController
  inherit_resources

  layout "stats"

  before_filter :require_user
  before_filter :admin_only

  protected
   
#  def per_page
#    20
#  end
end
