class Stats::PaidUsersController < Stats::ResourcesController
  sortable_attributes :name,:id
  def index
    if params[:search].blank?
    @users = User.find(:all).paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
    else
      @users = User.by_first_letter(params[:search]).paginate(:page => params[:page], :order =>"firstname ASC", :per_page => property(:results_per_page).to_i)
    end
    if @users.blank?
      flash[:notice] = t("controllers.search.empty")
    end
  end
  
  def show
  
  end
end
