class OndeegoController < ApplicationController
  before_filter :require_user
  before_filter :find_user
  before_filter :find_company

  self.allow_forgery_protection = false

  def company_create
    if property(:use_ondeego)
      @employee = @company.admin_employee
    else
      flash[:notice] = flash[:notice]
      redirect_to user_companies_path(current_user.id)
    end
  end

  def employee_create
    if property(:use_ondeego)
      @admin_employee = @company.admin_employee
      unless @admin_employee.ondeego_connect?
        flash[:error] = t("controllers.company_not_connect_with_appcentral")
        redirect_to user_employers_path(current_user.id)
      else
        @employee = @company.employee(current_user)
      end
    else
      flash[:notice] = flash[:notice]
      redirect_to user_employers_path(current_user.id)
    end
  end

  def login
    if property(:use_ondeego)
      @employee = @company.employee(current_user)
      report_maflormed_data if @employee.blank?
      unless @employee.ondeego_connect?
         flash[:error] = t("controllers.company_not_connect_with_appcentral")
         redirect_to application_user_companies_path(current_user.id)
      end
    else
      flash[:error] = t("controllers.appcentral_not_use")
      redirect_to user_dashboard_index_path(current_user.id)
    end
  end

  protected
  def find_user
    @user = User.find_by_id params[:user_id]
    report_maflormed_data unless @user == current_user
  end

  def find_company
    @company = @user.employers.find_by_id params[:company_id]
    report_maflormed_data if @company.blank?
  end


end
