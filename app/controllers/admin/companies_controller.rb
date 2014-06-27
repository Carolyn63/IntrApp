class Admin::CompaniesController < Admin::ResourcesController
  actions :index, :show, :edit, :update, :destroy

  sortable_attributes :created_at, :name, :id, :address, :city, :address, 
                      :phone, :company_type, :industry, :size, :team,
                      :privacy

  def employees
    @employees = resource.employees.by_status(params[:status]).paginate :page => params[:page], :include => :user
  end

  def invite
    @employee = Employee.find_by_id(params[:employee_id])
    @employee.deliver_invite!
    flash[:notice] = t("controllers.invitation_sent")
    redirect_to employees_admin_company_path(resource)
  end

  def destroy
    super do |format|
      format.html do
        unless @company.errors.empty?
          flash[:alert] = t("controllers.failed_delete_company_admin") + "#{@company.errors.on_base.blank? ? '' : @company.errors.on_base}"
        end
        redirect_to collection_url
      end
    end
  end

  protected
  def collection
    if params[:search].blank?
      @companies ||= end_of_association_chain.by_privacy(params[:privacy]
                                      ).paginate(:page => params[:page], :order => "companies." + sort_order(:default => "descending"))
    else
      #filters = {}
      #filters[:privacy] = params[:privacy] unless params[:privacy].blank?
      #@companies ||= end_of_association_chain.search(params[:search], :with => filters,
                                                    #:page => params[:page], :order => "name ASC", :star => true)
     @companies ||= end_of_association_chain.by_first_letter(params[:search]).by_privacy(params[:privacy]
                                      ).paginate(:page => params[:page], :order => "companies." + sort_order(:default => "descending"))
    end
  end

end
