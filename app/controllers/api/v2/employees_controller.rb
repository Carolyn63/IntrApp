class Api::V2::EmployeesController < ApplicationController
  before_filter :require_user
  before_filter :find_employee
  before_filter :only_owner

  def create_success
    success = @employee.ondeego_connect!(params[:userId])
    success ? flash[:notice] = t("controllers.appcentral_employee_created") : flash[:error] = @employee.errors.full_messages.join("\n")
    redirect_to root_path
  end

  def create_fail
    @employee.fail_ondeego_connect!
    flash[:error] = t("controllers.integrate_with_appcentral_failed") + " #{params["ondeegoErrorMsg"].to_s}"

    redirect_to root_path
  end

  def login_fail
    flash[:error] = t("controllers.integrate_with_appcentral_failed") + " #{params["ondeegoErrorMsg"].to_s}"
    redirect_to root_path
  end

  protected
  def find_employee
    @employee = Employee.find_by_perishable_token(params[:employee_key])
    report_integrate_problem if @employee.blank?
  end

  def only_owner
    report_integrate_problem if @employee.user != current_user
  end

end
