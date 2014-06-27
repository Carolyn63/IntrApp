class Api::V2::CompaniesController < ApplicationController
  before_filter :require_user
  before_filter :find_company_and_employee
  before_filter :only_owner

  def create_success
    @company.ondeego_connect!(params[:companyId])
    success = @employee.ondeego_connect!(params[:userId])
    success ? flash[:notice] = t("controllers.appcentral_company_created") : flash[:error] = @employee.errors.full_messages.join("\n")
    redirect_to root_path
  end

  def create_fail
    @company.fail_ondeego_connect!
    @employee.fail_ondeego_connect!
    flash[:error] = t("controllers.integrate_with_appcentral_failed") + " #{params["ondeegoErrorMsg"].to_s}"
    redirect_to root_path
  end

  protected
  def find_company_and_employee
    @company = Company.find_by_perishable_token(params[:company_key])
    @employee = Employee.find_by_perishable_token(params[:employee_key])
    report_integrate_problem if @company.blank? || @employee.blank?
  end

  def only_owner
    report_integrate_problem if !@company.owner?(current_user) && @employee.user != current_user
  end

end
