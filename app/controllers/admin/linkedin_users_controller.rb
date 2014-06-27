class Admin::LinkedinUsersController < Admin::ResourcesController

	actions :index
	sortable_attributes :lastname, :id

	protected
	def collection
		if params[:search].blank?
			@linkedin_users ||= end_of_association_chain.ordered.paginate(:page => params[:page], :order => "linkedin_users." + sort_order(:default => "ascending"))
		else
			@linkedin_users ||= end_of_association_chain.by_first_letter(params[:search]).ordered.paginate(:page => params[:page], :order => "linkedin_users." + sort_order(:default => "ascending"))
		end
	end

end