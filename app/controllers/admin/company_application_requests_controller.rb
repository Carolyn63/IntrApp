class Admin::CompanyApplicationRequestsController < Admin::ResourcesController
  actions :index

  sortable_attributes :requested_at, :company => "companies.name", :application => "applications.name"

  def approve
    unless resource.approved?
      resource.approve!
      if resource.errors.empty?
        flash[:notice] = t("controllers.success_accept_request")
      else
        flash[:error] = t("controllers.error_accept_request") + "<br/> #{resource.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
      end
    end
    redirect_to admin_company_application_requests_path
  end

  def reject
    unless resource.rejected?
      resource.reject!
      if resource.errors.empty?
        flash[:notice] = t("controllers.success_reject_request")
      else
        flash[:error] = t("controllers.error_reject_request") + "<br/> #{resource.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
      end
    end
    redirect_to admin_company_application_requests_path
  end

  protected

  def resource_class
    Companification
  end

  def collection
    get_collection_ivar || set_collection_ivar(
      Companification.pending.paginate(:page => params[:page], :include => [:company, :application], :order => sort_order(:default => "descending"))
    )
  end

  def resource
    @request ||= Companification.find(params[:id])
  end
end
