class ApplicationRequestsController < ApplicationController
  before_filter :require_user
  before_filter :find_company
  before_filter :only_owner, :only => [:index, :incoming_employee_requests, :approve, :reject, :resend_company_request]
  before_filter :find_employee, :only => [:employee_requests, :resend_employee_request]
  before_filter :find_employee_application, :only => [:approve, :reject]
  def index
    @company_application_requests = @company.companifications.pending_or_rejected.paginate(:page => params[:page], :per_page => 6, :order => "status asc, requested_at desc")
  end

  def incoming_employee_requests
    @incoming_employee_requests = @company.employee_application_requests.paginate(:page => params[:page], :per_page => 6, :order => "status asc, requested_at desc")
  end

  def employee_requests
    @employee_application_requests = @employee.employee_applications.pending_or_rejected.paginate(:page => params[:page], :per_page => 6, :order => "status asc, requested_at desc")
  end

  def approve
    unless @employee_application.approved?
      plan = ApplicationPlan.find_by_application_id_and_application_nature(@employee_application.application_id,"basic")
                  @employee_application.approve!
                  if @employee_application.errors.empty?
		    app = Application.find_by_id(@employee_application.application_id)
                    employee = Employee.find_by_id(@employee_application.employee_id)
		    if app.name.delete(' ').downcase.include?("ippbx")
                    PortalIppbxController.new.add_user_ippbx(employee.user_id, false)
		    elsif app.name.delete(' ').downcase.include?("cloud") 
		     PortalCloudstorageController.new.add_user(employee.user_id)
                    end
                  flash[:notice] = t("controllers.success_accept_request")
                  else
                  flash[:error] = t("controllers.error_accept_request") + "<br/> #{@employee_application.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
                  end
                
      redirect_to incoming_employee_requests_company_application_requests_path(@company)
     end
  end

  def reject
    unless @employee_application.rejected?
      @employee_application.reject!
      if @employee_application.errors.empty?
      flash[:notice] = t("controllers.success_reject_request")
      else
      flash[:error] = t("controllers.error_reject_request") + "<br/> #{@employee_application.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
      end
    end
    redirect_to incoming_employee_requests_company_application_requests_path(@company)
  end

  def resend_company_request
    @companification = @company.companifications.find params[:id]
    if @companification.rejected?
      @companification.resend!
      if @companification.errors.empty?
      flash[:notice] = t("controllers.success_resent_request")
      else
      flash[:error] = t("controllers.error_resend_request") + "<br/> #{@companification.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
      end
    end
    redirect_to :back
  end

  def resend_employee_request
    @employee_application = @employee.employee_applications.find params[:id]
    if @employee_application.rejected?
      @employee_application.resend!
      if @employee_application.errors.empty?
      flash[:notice] = t("controllers.success_resent_request")
      else
      flash[:error] = t("controllers.error_resend_request") + "<br/> #{@employee_application.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
      end
    end
    redirect_to :back
  end

  protected
  
  def handle_ippbx ids
    
    
  end

  def find_company
    @company = current_user.employers.find_by_id params[:company_id]
    report_maflormed_data if @company.blank?
  end

  def only_owner
    report_maflormed_data(t("controllers.access_denied")) unless @company.admin == current_user
  end

  def find_employee
    report_maflormed_data and return if current_own_company
    @employee = @company.employees.find_by_id params[:employee_id]
    report_maflormed_data if @employee.blank?
  end

  def find_employee_application
    @employee_application = @company.employee_application_requests.find_by_id params[:id]
    report_maflormed_data if @employee_application.blank?
  end


end
