class Admin::AuditsController < Admin::ResourcesController
  actions :index, :show, :edit, :update, :destroy

  sortable_attributes :created_at, :name, :id, :auditable_type, :auditable_id, :status, :parent_id

  def association_audits
    @audits = Audit.by_all_associations_audits(resource
                    ).by_status(params[:status]
                    ).by_auditable_type(params[:type]
                    ).paginate(:page => params[:page], :order => "audits." + sort_order(:default => "descending"))
  end

  def new_email
    @audit = resource
    @default_emails = ""
  #  @default_subject = "Problem with #{@audit.auditable_type} #{@audit.name}(#{@audit.auditable_id})"
  end

  def send_emails
    @audit = resource
    @default_emails = ""
    valid = !params[:emails].blank? && params[:emails].split(/[\,\;\s]+/).all?{|el| el =~ Authlogic::Regex.email}
    unless valid
      flash[:error] = "Please, enter emails"
      render :action => "new_email"
    else
      @audit.deliver_audit_message(params[:emails])
      flash[:notice] = t("controllers.deleted_audit_sent")
      redirect_to collection_url
    end
  end

  protected
  def collection
    @audits ||= end_of_association_chain.by_status(params[:status]
                                      ).by_auditable_type(params[:type]
                                      ).paginate(:page => params[:page], :order => "audits." + sort_order(:default => "descending"))
  end

end
