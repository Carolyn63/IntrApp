module ApplicationsHelper

  ACTIONS_TO_TITLE = {"index" => I18n.t("views.applications.market_place"),
    "company_catalog" => I18n.t("views.applications.company_catalog"),
    "my_applications" => I18n.t("views.applications.my_applications")}

  def applications_page_title
    search_or_filter = %w{search employees_in departments_in application_type_id devices_in categories_in}.any?{|f| params[f.to_s].present? }
    if search_or_filter
    I18n.t("views.applications.search_result_in", :name => ACTIONS_TO_TITLE[controller.action_name].to_s)
    else
    I18n.t("views.applications.full_list_title")
    end
  end

  def path_for_application_search
    if (session[:app_current_tab] || controller.action_name) == "index"
    user_applications_path(current_user)
    elsif (session[:app_current_tab] || controller.action_name) == 'company_catalog'
    company_catalog_user_applications_path(current_user)
    elsif (session[:app_current_tab] || controller.action_name) == 'my_applications'
    my_applications_user_applications_path(current_user)
    else
    user_applications_path(current_user)
    end
  end

  def status_li(status)
    content_tag(:li) do
      content_tag(:h4, :class=>"orange-color") do
        content_tag(:strong, t("views.applications.status")) + " " + h(Companification::Status::TO_LIST[status])
      end
    end
  end

  def status_li1(status)
    content_tag(:li) do
      content_tag(:h4, :class=>"orange-color") do
        content_tag(:strong, t("views.applications.status")) + " " + h(Companification::Status::TO_LIST[status])
      end
    end
  end

  def request_links(application, request)
    label, url = if current_own_company.present?
      if application.basic_plan.payment_type == "free"
        if request.blank?
          [t("views.applications.purchase_application"), send_request_user_application_path(current_user, application, :company_id => current_own_company.id)]
        elsif request.rejected?
          [t("views.application_requests.resend_request"), resend_company_request_company_application_request_path(current_own_company, request)]
        end
      elsif request.blank?
        [t("views.applications.purchase_application"), create_app_order_user_order_path(current_user, application, :company_id => current_own_company.id, :plan_id => application.basic_plan.id)]
      else
        if request.cancelled? or request.blank?
          [t("views.applications.purchase_application"), create_app_order_user_order_path(current_user, application, :company_id => current_own_company.id, :plan_id => application.basic_plan.id)]
        end
      end
    elsif current_employee
      if request.blank?
        [t("views.applications.get_application"), send_employee_request_user_application_path(current_user, application, :employee_id => current_employee.id)]
      elsif request.rejected?
        [t("views.application_requests.resend_request"), resend_employee_request_company_application_request_path(current_employee.company_id, request, :employee_id => current_employee.id)]
      end
    end

    content_tag(:p, link_to(link_name(label), url, :method => :put, :class => 'standart-button')) if label.present? && url.present?

  end

  def request_ippbx_links(application, request, operation)
    label, url =  if current_employee
      if request.blank?
        [t("views.applications.add_ippbx"), add_user_ippbx_user_application_path(current_user, application, :employee_id => current_employee.id)]
      elsif operation == "remove"
        [t("views.applications.remove_ippbx"), remove_user_ippbx_user_application_path(current_user, application, :employee_id => current_employee.id)]
      end
    end

    if operation == "remove"
    content_tag(:p, link_to(link_name(label), url, :method => :put, :class => 'standart-button', :confirm => t("views.employees.warning_ippbx_remove"))) if label.present? && url.present?
    else
    content_tag(:p, link_to(link_name(label), url, :method => :put, :class => 'standart-button')) if label.present? && url.present?
    end

  end

  def get_operating_system device
    if device['HTTP_USER_AGENT'].downcase.match(/mac/i)
    "Mac"
    elsif device['HTTP_USER_AGENT'].downcase.match(/windows/i)
    "Windows"
    elsif device['HTTP_USER_AGENT'].downcase.match(/linux/i)
    "Linux"
    elsif device['HTTP_USER_AGENT'].downcase.match(/unix/i)
    "Unix"
    elsif device['HTTP_USER_AGENT'].downcase.match(/android/i)
    "Android"
    elsif device['HTTP_USER_AGENT'].downcase.match(/ios/i)
    "Unix"
    elsif device['HTTP_USER_AGENT'].downcase.match(/kindle/i)
    "Unix"
    else
    "Unknown"
    end
  end

end
