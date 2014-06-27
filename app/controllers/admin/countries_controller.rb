class Admin::CountriesController < Admin::ResourcesController
	actions :all

	sortable_attributes :country, :id, :applications_count

	protected
	def collection
		@countries ||= end_of_association_chain.paginate(:page => params[:page], :per_page => 50, :order => "countries." + sort_order(:default => "ascending"))
	end

end

