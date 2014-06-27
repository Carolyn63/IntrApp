require 'net/http'
require 'uri'

class SogoController < ApplicationController
  before_filter :require_user
  before_filter :find_user
  before_filter :find_company

  def login
    if property(:use_sogo)
      @employee = @company.employee(current_user)
      report_maflormed_data if @employee.blank?
      unless @employee.sogo_connect?
        flash[:error] = t("controllers.not_connect_to_sogo")
        redirect_to application_user_companies_path(current_user.id)
      else

#        begin
#          Timeout::timeout(10) do
#            RestClient.get("#{property(:sogo_url)}/so/#{cookies["sogo_email"]}/logoff") unless cookies["sogo_email"].blank?
#          end
#        rescue
#          RAILS_DEFAULT_LOGGER.info "Logout: timeout connect to Sogo"
#        end

        prev_email = cookies["sogo_email"]
        cookies["sogo_email"] = {"value" => @employee.company_email,
                                 "path" => "/",
                                 "expires" => nil,
                                 "domain" => property(:sogo_email_domain)}

        if prev_email.blank?
          redirect_to "#{property(:cas_url)}/logout?service=#{property(:sogo_url)}&gateway=1"
        else
          redirect_to "#{property(:cas_url)}/login_sogo?logout_link=#{property(:sogo_url)}/so/#{prev_email}/logoff&service=#{property(:sogo_url)}"
        end
      end
    else
      flash[:error] = t("controllers.sogo_not_use")
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
