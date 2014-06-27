class Admin::HelpUrlsController < Admin::ResourcesController
  
  sortable_attributes :created_at, :name, :portal_url, :help_url


   protected
  def collection
    @help_urls ||= end_of_association_chain.paginate(:page => params[:page], :order => "help_urls." + sort_order(:default => "descending"))
  end
end
