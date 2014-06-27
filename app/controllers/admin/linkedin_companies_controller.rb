class Admin::LinkedinCompaniesController < Admin::ResourcesController
	actions :index
	sortable_attributes :name, :id

	protected
	def collection
		if params[:search].blank?
			@linkedin_companies ||= end_of_association_chain.ordered.paginate(:page => params[:page], :order => "linkedin_companies." + sort_order(:default => "ascending"))
		else
			@linkedin_companies ||= end_of_association_chain.by_first_letter(params[:search]).ordered.paginate(:page => params[:page], :order => "linkedin_companies." + sort_order(:default => "ascending"))
		end
	end

end