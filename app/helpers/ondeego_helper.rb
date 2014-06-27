module OndeegoHelper

  def remove_ondeego_company_optional_fields(fields)
    fields.delete_if do |key, value| 
      ["phone", "address", "city", "state", "countryISOCode", "companyLogoURL"].include?(key) &&
      value.blank?
    end
  end

  def remove_ondeego_employee_optional_fields(fields)
    fields.delete_if do |key, value|
      ["address", "city", "state", "countryISOCode"].include?(key) &&
      value.blank?
    end
  end

  def company_ondeego_form(employee, company)
    company_fields = {"email" => employee.company_email.to_s,
                      "firstName" => employee.user.firstname.to_s,
                      "lastName" => employee.user.lastname.to_s,
                      "jobTitle" => employee.ondeego_job_title,
                      "phone" => employee.phone.to_s,
                      "address" => employee.user.address.to_s,
                      "city" => employee.user.city.to_s,
                      "state" => employee.user.state.to_s,
                      "countryISOCode" => employee.user.iso_country_code.to_s,
                      "companyName" => company.name.to_s,
                      "companyLogoURL" => URI.escape(property(:app_site) + company.logo.url(:original,false).to_s),
                      "numberEmployeesAllowed" => "0",
                      "successRedirectURL" => success_redirect_url(company),
                      "failureRedirectURL" => failure_redirect_url(company)
                      }
     company_fields = remove_ondeego_company_optional_fields(company_fields)

    oauth_parameters = Services::OnDeego::OauthHelper.oauth_parameters(:request_url => Services::OnDeego::OauthClient::ACTIONS::CREATE_COMPANY,
                                                                       :parameters => company_fields)
    content_tag(:div, :id => "ondeego_company", :style => "display:none") do
      form_tag Services::OnDeego::OauthClient::ACTIONS::CREATE_COMPANY, :id => "ondeego_new_company", :content_type => "application/x-www-form-urlencoded" do
        oauth_parameters.each do |f,v|
          concat(hidden_field_tag(f.to_s, v.to_s))
        end
        company_fields.each do |f,v|
          concat(hidden_field_tag(f.to_s, v.to_s))
        end
        concat(submit_tag("", :style => "display:none", :disabled => true))
      end
      concat(javascript_tag("document.getElementById('ondeego_new_company').submit()"))
    end
  end

  def employee_ondeego_form(employee, admin_employee)
    employee_fields = {"email" => employee.company_email,
                      "firstName" => employee.user.firstname,
                      "lastName" => employee.user.lastname,
                      "jobTitle" => employee.ondeego_job_title,
                      "phone" => employee.phone.to_s,
                      "address" => employee.user.address,
                      "city" => employee.user.city,
                      "state" => employee.user.state,
                      "countryISOCode" => employee.user.iso_country_code,
                      "companyId" => employee.company.ondeego_company_id.to_s,
                      "successRedirectURL" => success_redirect_url(employee),
                      "failureRedirectURL" => failure_redirect_url(employee)}

    employee_fields = remove_ondeego_employee_optional_fields(employee_fields)

    oauth_parameters = Services::OnDeego::OauthHelper.oauth_parameters(
                                  :request_url => Services::OnDeego::OauthClient::ACTIONS::CREATE_EMPLOYEE,
                                  :oauth_token => admin_employee.oauth_token,
                                  :oauth_secret => admin_employee.oauth_secret,
                                  :parameters => employee_fields)
    content_tag(:div, :id => "ondeego_employee", :style => "display:none") do
      form_tag Services::OnDeego::OauthClient::ACTIONS::CREATE_EMPLOYEE, :id => "ondeego_new_employee", :content_type => "application/x-www-form-urlencoded" do
        oauth_parameters.each do |f,v|
          concat(hidden_field_tag(f.to_s, v.to_s))
        end
        employee_fields.each do |f,v|
          concat(hidden_field_tag(f.to_s, v.to_s))
        end
        concat(submit_tag("", :style => "display:none", :disabled => true))
      end
      concat(javascript_tag("document.getElementById('ondeego_new_employee').submit()"))
    end
  end

  def ondeego_form_login(employee)
    form_id = "ondeego_login_form_#{employee.ondeego_user_id}"
    login_url = Services::OnDeego::OauthClient::ACTIONS::LOGIN
    login_fields = {"userId" => employee.ondeego_user_id.to_s,
                    "failureRedirectURL" => login_fail_api_v2_employees_url("employee_key" => employee.perishable_token, :escape => false)}
    oauth_parameters = Services::OnDeego::OauthHelper.oauth_parameters(:request_url => login_url,
                                                      :oauth_token => employee.oauth_token,
                                                      :oauth_secret => employee.oauth_secret,
                                                      :parameters => login_fields)
    content_tag(:div, :id => "ondeego_login") do
      form_tag login_url, :id =>form_id, :method => :post do
        oauth_parameters.each do |f,v|
          concat(hidden_field_tag(f.to_s, v.to_s))
        end
        login_fields.each do |f,v|
          concat(hidden_field_tag(f.to_s, v.to_s))
        end
        concat(submit_tag("", :style => "display:none", :disabled => true))
      end
      concat(javascript_tag("document.getElementById('#{form_id}').submit()"))
    end
  end

end
