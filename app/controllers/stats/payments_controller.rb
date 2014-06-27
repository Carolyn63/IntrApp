class Stats::PaymentsController < Stats::ResourcesController
	sortable_attributes :name,:id

	def index
		@services = Service.find(:all).paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
		if @services.blank?
			flash[:notice] = t("controllers.search.empty")
		end
	end

	def show
	end

end
