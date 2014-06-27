class EmployersController < ApplicationController
  before_filter :require_user
  before_filter :find_user
  before_filter :find_company, :only => [:accept,:reject]
  before_filter :find_employee, :only => [:accept,:reject]
  before_filter :check_active_employees, :only => [:accept]

  def index
    params[:status] ||= Employee::Status::PENDING
    @employers = @user.employers.by_search(params[:search]).by_employee_status(params[:status]).paginate :page => params[:page], :order => "employees.status ASC, employees.created_at DESC",
                                          :include => [:employees]
  end

  def accept
    unless @employee.active?
      @employee.accept

      if @employee.errors.empty?
        flash[:notice] = t("controllers.success_accept_invite")
        if property(:use_ondeego)
        redirect_to employee_create_user_ondeego_path(current_user, :company_id => @company.id)
        else
        redirect_to user_employers_path(current_user.id)
        end
      else
        flash[:error] = t("controllers.error_accept_invite") + "<br/> #{@employee.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
        redirect_to user_employers_path(current_user.id)
      end
    else
      flash[:notice] = t("controllers.employee_accepted_already")
      redirect_to user_employers_path(current_user.id)
    end
  end

  def reject
    unless @employee.rejected?
      @employee.reject

      if @employee.errors.empty?
        flash[:notice] = t("controllers.success_rejected_employee", :sp_name => property(:sp_name))
      else
        flash[:error] = t("controllers.error_reject_invite") + "<br/> #{@employee.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
      end
    else
      flash[:notice] = t("controllers.employee_rejected_already")
    end
    redirect_to :back
  end

  protected

  def find_company
    @company = current_user.employers.find_by_id params[:id]
    report_maflormed_data if @company.blank?
  end

  def find_employee
    @employee = @company.employee(current_user)
  end

  def find_user
    @user = User.find_by_id params[:user_id]
    report_maflormed_data unless @user == current_user
  end

  def check_active_employees
    if !property(:multi_company) && current_user.has_active_employee?
      flash[:error] = t("controllers.users_may_be_employee_only_one_company")
      redirect_to user_employers_path(current_user, :status => Employee::Status::ACTIVE)
    end
  end
end
