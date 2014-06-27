# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  include SortableTable::App::Helpers::ApplicationHelper

  def menu_item_permited?( user, item )
    true
  end

  def application_main_menu
    main = [
            {
              :name => t("helpers.application.dashboard"),
              :path => "user_dashboard_index_path(current_user.id)",
              :permissions => [],
              :controllers => {"dashboard" => ["index"]},
              :submenu => [],
            },
            {
              :name => t("helpers.application.people"),
              :path => "users_path",
              :permissions => [],
              :controllers => {"employees" => ["people", "contacts"], "users" => ["index"]},
              :submenu => [],
            },
            {
              :name => t("helpers.application.companies"),
              :path => "user_companies_path(current_user.id)",
              :permissions => [],
              :controllers => {"companies" => ["index"]},
              :submenu => [],
            },
            {
              :name => t("helpers.application.my_contacts"),
              :path => "contacts_user_path(current_user)",
              :permissions => [],
              :controllers => {"users" => ["contacts"]},
              :submenu => [],
            },
            
    
#	    {
#              :name => t("helpers.application.search"),
#              :path => "users_search_path",
#              :permissions => [],
#              :controllers => {"search" => []},
#              :submenu => [],
#            },
    
         ]

	 main[4] = 
              {
              :name => t("helpers.application.application"),
              :path => "user_applications_path(current_user)",
              :permissions => [],
              :controllers => {"applications" => []},
              :submenu => [],
            }
	 main[5] =  
	    {
              :name => t("helpers.application.manage"),
              :path => "#",
              :permissions => [],
              :controllers => {"users" => ["edit", "update", "show", "friends"], 
                               "companies" => ["new", "create", "edit", "update", "show"],
                               "employees" => ["index", "new", "create", "edit", "update", "new_recruit", "recruit"]},
              :submenu => manage_menu,
            }

    main
  end

  def manage_menu
    menu = [
       {
          :name => t("helpers.application.personal_profile"),
          :path => "edit_user_path(current_user.id)",
          :permissions => [],
          :controllers => {},
          :submenu => [],
       },
       {
          :name => t("helpers.application.create_company"),
          :path => "new_user_company_path(current_user)",
          :permissions => [],
          :controllers => {},
          :submenu => [],
       },
       {
          :name => t("helpers.application.friends"),
          :path => "friends_user_path(current_user)",
          :permissions => [],
          :controllers => {"users" => ["friends"]},
          :submenu => [],
       },
       {
          :name => t("helpers.application.friendship_request"),
          :path => "incoming_requests_user_friendships_path(current_user)",
          :permissions => [],
          :controllers => {"friendships" => ["index"]},
          :submenu => [],
       },
       {
          :name => t("helpers.application.manage_invitation"),
          :path => "user_employers_path(current_user)",
          :permissions => [],
          :controllers => {"employers" => ["index"]},
          :submenu => [],
       },
    ]

    if current_user.owner_companies?
      menu.insert(2, {
                        :name => t("helpers.application.manage_employees"),
                        :path => "company_employees_path(current_user.companies.first)",
                        :permissions => [],
                        :controllers => {},
                        :submenu => [],
                     })
    end

    if !property(:multi_company) && current_user.has_active_employee?
      if current_user.owner_companies?
        menu[1] = {
                    :name => t("helpers.application.manage_company"),
                    :path => "edit_company_path(current_user.companies.first)",
                    :permissions => [],
                    :controllers => {},
                    :submenu => [],
                  }
	    menu << {
                  :name => t("helpers.application.company_app_requests"),
                  :path => "company_application_requests_path(current_own_company)",
                  :permissions => [],
                  :controllers => {},
                  :submenu => []
                 }
      else
        menu[1] = {
                    :name => t("helpers.application.view_company"),
                    :path => "company_path(current_user.first_active_employee.company_id)",
                    :permissions => [],
                    :controllers => {},
                    :submenu => [],
                  }
      end
    end
    
     if current_user.has_active_employee?
       unless current_own_company
         menu << {
                :name => t("helpers.application.app_requests"),
                :path => "employee_requests_company_application_requests_path(current_employee.company_id, :employee_id => current_employee.id)",
                :permissions => [],
                :controllers => {},
                :submenu => []
               }
       end
       menu << {
                :name => t("helpers.application.my_devices"),
                :path => "devices_company_employee_path(current_user.first_active_employee.company_id, current_user.first_active_employee)",
                :permissions => [],
                :controllers => {"employees" => ["device", "update_device"]},
                :submenu => []
               }
    end
    
    if current_user.owner_companies?
      menu << {
                :name => t("helpers.application.manage_payments"),
                :path => "payment_requests_user_path(current_user)",
                :permissions => [],
                :controllers => {},
                :submenu => []
               }
               
    end
    
      if current_user.owner_companies?
        menu << {
                :name => t("helpers.application.orders"),
                :path => "cart_user_orders_path(current_user)",
                :permissions => [],
                :controllers => {},
                :submenu => []
               }
      end
	  
	  if current_user.owner_companies?
        menu << {
                :name => t("helpers.application.stats"),
                :path => "cost_trend_app_company_stat_path(current_own_company.id)",
                :permissions => [],
                :controllers => {},
                :submenu => []
               }
      end
    
    
    	   
    menu
  end

  def friendship_menu
    [
       {
          :name => t("helpers.application.income_requests"),
          :path => "incoming_requests_user_friendships_path(current_user.id)",
          :permissions => [],
          :controllers => {"friendships" => ["incoming_requests"]},
          :submenu => [],
       },
       {
          :name => t("helpers.application.outcome_requests"),
          :path => "outcoming_requests_user_friendships_path(current_user)",
          :permissions => [],
          :controllers => {"friendships" => ["outcoming_requests"]},
          :submenu => [],
       },
       {
          :name => t("helpers.application.rejected_outcome_request"),
          :path => "rejected_outcoming_requests_user_friendships_path(current_user)",
          :permissions => [],
          :controllers => {"friendships" => ["rejected_outcoming_requests"]},
          :submenu => [],
       },
    ]
  end

	def application_admin_main_menu
		admin_menu = [
			{
				:name => t("helpers.application.users"),
				:path => "admin_users_path",
				:permissions => [],
				:controllers => {"admin/users" => []},
				:submenu => [],
			},
			{
				:name => t("helpers.application.companies"),
				:path => "admin_companies_path",
				:permissions => [],
				:controllers => {"admin/companies" => []},
				:submenu => [],
			},
			{
				:name => "LinkedIn Users",
				:path => "admin_linkedin_users_path",
				:permissions => [],
				:controllers => {"admin/linkedin_users" => []},
				:submenu => [],
			},
			{
				:name => "LinkedIn Companies",
				:path => "admin_linkedin_companies_path",
				:permissions => [],
				:controllers => {"admin/linkedin_companies" => []},
				:submenu => [],
			},
			{
				:name => t("helpers.application.deleted_audit"),
				:path => "admin_audits_path",
				:permissions => [],
				:controllers => {"admin/audits" => []},
				:submenu => [],
			},
=begin
			{
				:name => t("helpers.application.help_url"),
				:path => "admin_help_urls_path",
				:permissions => [],
				:controllers => {"admin/help_urls" => []},
				:submenu => [],
			},
=end
			{
				:name => 'Applications',
				:path => "admin_applications_path",
				:permissions => [],
				:controllers => {"admin/applications" => []},
				:submenu => [],
			},
			{
				:name => t("helpers.application.application_plans"),
				:path => "admin_application_plans_path",
				:permissions => [],
				:controllers => {"admin/application_plans" => []},
				:submenu => [],
			},
			{
				:name => 'Application Types',
				:path => "admin_application_types_path",
				:permissions => [],
				:controllers => {"admin/application_types" => []},
				:submenu => [],
			},
			{
				:name => t("helpers.application.devices"),
				:path => "admin_devices_path",
				:permissions => [],
				:controllers => {"admin/devices" => []},
				:submenu => [],
			},
			{
				:name => 'Categories',
				:path => "admin_categories_path",
				:permissions => [],
				:controllers => {"admin/categories" => []},
				:submenu => [],
			},
			 {
				:name => 'Industries',
				:path => "admin_industries_path",
				:permissions => [],
				:controllers => {"admin/industries" => []},
				:submenu => [],
			},
			 {
				:name => 'Countries',
				:path => "admin_countries_path",
				:permissions => [],
				:controllers => {"admin/countries" => []},
				:submenu => [],
			},
			{
				:name => t("helpers.application.company_application_requests"),
				:path => "admin_company_application_requests_path",
				:permissions => [],
				:controllers => {"admin/company_application_requests" => []},
				:submenu => [],
			},
		]

		if property(:use_billing)
			admin_menu <<  {
				:name => t("helpers.application.user_payment_requests"),
				:path => "admin_user_payment_requests_path",
				:permissions => [],
				:controllers => {"admin/user_payment_requests" => []},
				:submenu => [],
			}

			admin_menu <<  {
				:name => t("helpers.application.stats"),
				:path => "admin_stats_path",
				:permissions => [],
				:controllers => {"admin/stats" => []},
				:submenu => [],
			}
		end

		admin_menu   
	end

	def application_stats_main_menu
		[
			{
				:name => t("helpers.application.registered_linkedin_companies"),
				:path => "stats_registered_linkedin_companies_path",
				:permissions => [],
				:controllers => {"stats/registered_linkedin_companies"=> []},
				:submenu => [],
			},
			{
				:name => t("helpers.application.registered_linkedin_users"),
				:path => "stats_registered_linkedin_users_path",
				:permissions => [],
				:controllers => {"stats/registered_linkedin_users"=> []},
				:submenu => [],
			},
			{
				:name => t("helpers.application.registered_users"),
				:path => "stats_registered_users_path",
				:permissions => [],
				:controllers => {"stats/registered_users"=> []},
				:submenu => [],
			},
			{
				:name => t("helpers.application.paid_users"),
				:path => "stats_paid_users_path",
				:permissions => [],
				:controllers => {"stats/paid_users_path"=> []},
				:submenu => [],
			},
			{
				:name => t("helpers.application.payment_history"),
				:path => "stats_payments_path",
				:controllers => {"stats/payments"=> []},
				:submenu => [],
			}
		]
	end

  def application_sysadmin_main_menu
    [
        {
          :name => t("helpers.application.serviceproviders"),
          :path => "sysadmin_serviceproviders_path",
          :permissions => [],
          :controllers => {"sysadmin/serviceproviders" => []},
          :submenu => [],
        },
        {
          :name =>t("helpers.application.publicnumbers"),
          :path => "sysadmin_publicnumbers_path",
          :permissions => [],
          :controllers => {"sysadmin/publicnumbers" => []},
          :submenu => [],
        },
         {
          :name =>t("helpers.application.features"),
          :path => "sysadmin_features_path",
          :permissions => [],
          :controllers => {"sysadmin/features" => []},
          :submenu => [],
        },
        {
          :name => t("helpers.application.routingactions"),
          :path => "sysadmin_routingactions_path",
          :permissions => [],
          :controllers => {"sysadmin/routingactions" => []},
          :submenu => [],
        },
         {
          :name => t("helpers.application.pstns"),
          :path => "sysadmin_pstns_path",
          :permissions => [],
          :controllers => {"sysadmin/pstns" => []},
          :submenu => [],
        },
         {
          :name =>t("helpers.application.gatewaygroups"),
          :path => "sysadmin_gatewaygroups_path",
          :permissions => [],
          :controllers => {"sysadmin/gatewaygroups" => []},
          :submenu => [],
        },
        {
          :name =>t("helpers.application.prompts"),
          :path => "sysadmin_prompts_path",
          :permissions => [],
          :controllers => {"sysadmin/prompts" => []},
          :submenu => [],
        },
        {
          :name =>t("helpers.application.adminprofiles"),
          :path => "sysadmin_adminprofiles_path",
          :permissions => [],
          :controllers => {"sysadmin/adminprofiles" => []},
          :submenu => [],
        }
    
    ]
 end

  def application_spadmin_main_menu
    [
        {
          :name => t("helpers.application.enterprises"),
          :path => "spadmin_enterprises_path",
          :permissions => [],
          :controllers => {"spadmin/enterprises" => []},
          :submenu => [],
        },
         {
          :name => t("helpers.application.rdpgs"),
          :path => "spadmin_rdpgs_path",
          :permissions => [],
          :controllers => {"spadmin/rdpgs" => []},
          :submenu => [],
        },
   
         {
          :name => t("helpers.application.domains"),
          :path => "spadmin_domains_path",
          :permissions => [],
          :controllers => {"spadmin/domains" => []},
          :submenu => [],
        },
         {
          :name =>t("helpers.application.features"),
          :path => "spadmin_features_path",
          :permissions => [],
          :controllers => {"spadmin/features" => []},
          :submenu => [],
        },
        {
          :name =>t("helpers.application.publicnumbers"),
          :path => "spadmin_publicnumbers_path",
          :permissions => [],
          :controllers => {"spadmin/publicnumbers" => []},
          :submenu => [],
        },
        {
          :name =>t("helpers.application.spprofiles"),
          :path => "spadmin_spprofiles_path",
          :permissions => [],
          :controllers => {"spadmin/spprofiles" => []},
          :submenu => [],
        },
        {
          :name =>t("helpers.application.adminprofiles"),
          :path => "spadmin_adminprofiles_path",
          :permissions => [],
          :controllers => {"spadmin/adminprofiles" => []},
          :submenu => [],
        }
    
        ]
 end

 def application_entadmin_main_menu
    [
        {
          :name => t("helpers.application.users"),
          :path => "entadmin_users_path",
          :permissions => [],
          :controllers => {"entadmin/users" => []},
          :submenu => [],
        },
       {
          :name => t("helpers.application.features"),
          :path => "entadmin_features_path",
          :permissions => [],
          :controllers => {"entadmin/features" => []},
          :submenu => [],
        },
       
        {
          :name => t("helpers.application.entprofile"),
          :path => "entadmin_entprofiles_path",
          :permissions => [],
          :controllers=>{"entadmin/entprofiles" => []},
          :submenu => [],
        },
        {
          :name => t("helpers.application.adminprofile"),
          :path =>"entadmin_adminprofiles_path",
          :permissions => [],
          :controllers => {"entadmin/adminprofiles" => []},
          :submenu => [],
        },
    ]
  end
    def application_useradmin_main_menu
    [
           {
          :name => t("helpers.application.profiles"),
          :path =>"useradmin_profiles_path",
          :permissions => [],
          :controllers => {"useradmin/profiles" => []},
          :submenu => [],
        },
        {
          :name => t("helpers.application.callcontrols"),
          :path => "useradmin_callcontrols_path",
          :permissions => [],
          :controllers => {"useradmin/callcontrols" => []},
          :submenu => [],
        }
      
    
    ]
  end
  

      

  def success_redirect_url(company_or_employee)
    if company_or_employee.kind_of?(Company)
      create_success_api_v2_companies_url("company_key" => company_or_employee.perishable_token,
                                         "employee_key" => company_or_employee.employee(current_user).perishable_token,
                                         :escape => false)
    elsif company_or_employee.kind_of?(Employee)
      create_success_api_v2_employees_url("employee_key" => company_or_employee.perishable_token, :escape => false)
    else
      ""
    end
  end

  def failure_redirect_url(company_or_employee)
    if company_or_employee.kind_of?(Company)
      create_fail_api_v2_companies_url("company_key" => company_or_employee.perishable_token,
                                      "employee_key" => company_or_employee.employee(current_user).perishable_token,
                                      :escape => false)
    elsif company_or_employee.kind_of?(Employee)
      create_fail_api_v2_employees_url("employee_key" => company_or_employee.perishable_token, :escape => false)
    else
      ""
    end
  end

  def menu_search_select
    [
      [t("helpers.application.companies"), user_companies_path(current_user.id)],
      [t("helpers.application.people"), users_path]
    ]
  end

  def search_drop_down field_name, list, options = {}
    div_id = "div_" + field_name
    select_item = list[0]
    options[:ul_class] ||= "sub-ul-long"
    drop_down = ""
    list.each do |item|
      drop_down += content_tag(:li, %Q!<a rel="#{item[1]}" href="#">#{item[0]}</a>!)
      select_item = item if !options[:selected].blank? && item[1] == options[:selected]
    end
    content_tag(:span, :id => div_id) do
      concat(hidden_field_tag(field_name, select_item[1])) +
      content_tag(:ul, :class=>"drop-down") do
        content_tag(:li, :class => "current") do
          content_tag(:a, %Q!<b class="f"></b><b class="s #{options[:long].blank? ? '' : 's-big'}"><span id="current-item">#{select_item[0]}</span>&nbsp;#{image_tag("arrow_down.gif")}</b><b class="t"></b>!,
                          :class=>"grey-link") +
          content_tag(:div, :class => "sub-box") do
            content_tag(:ul, drop_down, :class => "sub-ul #{options[:ul_class]}")
          end
        end
      end
		end +
    #javascript_tag(%Q!$("##{div_id}").ui_dropdown("#{field_name}", #{options[:submit].blank? ? 0 : 1});!)
    javascript_tag(%Q!$("##{div_id}").ui_dropdown("#{field_name}");!)
  end

  def alphabetical_search_index action, params = {}
    letters = ""
    ("A".."Z").each do |letter|
      letters += content_tag(:li, link_to_function(letter, "$('#alphabet').val('#{letter.underscore}'); $('#alphabetical_search_form').submit();",
                                                  :style => (params[:alphabet].underscore == letter.underscore ? "color:#EE3C01" : "")))
    end
    title = content_tag(:span, %Q!#{t("helpers.application.alphabetical_index")}&nbsp;&nbsp;#{link_to_function("#", "$('#alphabet').val(''); $('#alphabetical_search_form').submit();")}!)
    content_tag(:div, :id => "alphabetical_index") do
      form_tag action, :id => "alphabetical_search_form", :method => :get do
        concat(hidden_field_tag("sort_by", params[:sort_by]))
        concat(hidden_field_tag("alphabet", params[:alphabet]))
        concat(content_tag(:p, title, :class=>"title"))
        concat(content_tag(:ul, letters, :class=>"alphabet-list"))
        concat(submit_tag("", :style => "display:none"))
      end
    end
  end

  def join_fields_with_pipe(first_field, second_field)
    fields = []
    fields << %Q!<span class="fz10 blue-color"><i><b>#{first_field}</b></i></span>&nbsp;! unless first_field.blank?
    fields << %Q!<span class="fz10 green-color">#{second_field}</span>! unless second_field.blank?
    fields.join(%Q!<span class="blue-color fz10">|</span>&nbsp;!)
  end

  def ondeego_device_type_list
#    ondeego = Services::OnDeego::Connector.new({
#        :smb_login => property(:ondeego_smb_login),
#        :smb_password => property(:ondeego_smb_password)
#      })
#    devices = ondeego.devices
    device_types = [
      ["iPhone (iPhone, mobile)", "iPhone"],
      ["iPhone 3GS (iPhone, mobile)", "iPhone 3GS"],
      ["iPhone 3G (iPhone, mobile)", "iPhone 3G"],
      ["iPhone 4 (iPhone, mobile)", "iPhone 4"],
      ["iPad (iPhone, netbook)", "iPad"],
      ["iPad 3G (iPhone, netbook)", "iPad 3G"],
      ["Compaq Mini CQ10 (MeeGo, netbook)", "Compaq Mini CQ10"],
      ["HTC Desire (Android, mobile)", "HTC Desire"],
      ["T-Mobile G1 (Android, mobile)", "T-Mobile G1"],
      ["HTC Hero (Android, mobile)", "HTC Hero"],
      ["HTC Droid Incredible (Android, mobile)", "HTC Droid Incredible"],
      ["HTC Evo 4G (Android, mobile)", "HTC Evo 4G"],
      ["Motorola Droid X (Android, mobile)", "Motorola Droid X"],
      ["Motorola Devour (Android, mobile)", "Motorola Devour"],
      ["T-Mobile myTouch 3G (Android, mobile)", "T-Mobile myTouch 3G"],
      ["Samsung Epic 4G (Android, mobile)", "Samsung Epic 4G"],
    ]
    device_types
  end

  def ondeego_device_os_list device_type = "iPhone"
    case device_type
    when "iPhone", "iPhone 3GS", "iPhone 3G", "iPhone 4", "iPad",
         "iPad 3G"
         [ ["2.0", "2.0"],
           ["2.1", "2.1"],
           ["2.2", "2.2"],
           ["2.2.1", "2.2.1"],
           ["3.0", "3.0"],
           ["3.1", "3.1"],
           ["3.1.2", "3.1.2"],
           ["3.1.3", "3.1.3"],
           ["3.2", "3.2"],
           ["4.0", "4.0"] ]
    when "Compaq Mini CQ10"
         [ ["1.0"],
           ["1.01"] ]
    when "HTC Desire", "T-Mobile G1", "HTC Hero", "HTC Droid Incredible", "Samsung Epic 4G",
         "HTC Evo 4G", "Motorola Droid X", "Motorola Devour", "T-Mobile myTouch 3G"
         [ ["1.6", "1.6"],
           ["2.0", "2.0"],
           ["2.1", "2.1"],
           ["2.2", "2.2"] ]
    else
         [[]]
    end
  end

  def menu_tab name
    %Q!<b class='f'></b><b class='s'>#{name}</b><b class='t'></b>!
  end

  def link_name name
    %Q!<b class="f"></b><b class="s">&nbsp;#{name}</b><b class="t"></b>!
  end

  def simple_button name
    %Q!<b class="f-small"></b><b class="s">&nbsp;#{name}</b><b class="t"></b>!
  end

  def wide_button name, width_class = "w140"
    %Q!<b class="f-small"></b><b class="s #{width_class.to_s}">&nbsp;#{name}</b><b class="t"></b>!
  end

  def default_value value, default = ""
    value.blank? ? default : value
  end
  
  def custom_default_value value1,value2, default = ""
    if value1.present?
	value1
	elsif value2.present?
	value2
	else
	default
	end
  end

  def value_or_no_information value
    value.blank? ? "" : value
  end

  def sogo_logout_if_need sogo_email
    unless sogo_email.blank?
      link = "#{property(:sogo_url)}/so/#{sogo_email}/logoff"
      javascript_tag(%Q!$(document).ready(function() {
                      try{
                          $.getScript('#{link}');
                          $.getScript('#{property(:cas_url)}/logout');
                          return false;
                      }catch(e) {}
                    });!)
    end
  end

#   def your_mobile_tribe
#     mobile_client_link = link_to_function("<div>#{image_tag('mt_logo.png')}<span class='text'>#{link_name(t("views.your_mobiletribe"))}</span></div>", "window.open('#{property(:mobile_client_link)}','','scrollbars=no,menubar=no,height=400,width=500,resizable=yes,toolbar=no,location=no,status=no');", :class=>"green-color green-link without_underline")
#     if !cookies["mt_client_link_click"].blank? && cookies["mt_client_link_click"] == "1"
#       mobile_client_link
#     else
#       link_to("<div>#{image_tag('mt_logo.png')}<span class='text'>#{link_name(t("views.your_mobiletribe"))}</span></div>", mobile_tribe_description_support_path(:width => "500", :height=>"270"), :title => t("views.mobile_tribe_client.title"), :class=>"thickbox green-color green-link without_underline", :id => "mobile_client_id") +
#       javascript_tag(%Q!$("#mobile_client_id").click(function(event){
#                         $(".mt_button").replaceWith(#{('<div class=\'mt_button\'>' + mobile_client_link + '</div>').to_json})
#                         return false;
#                       })!)
#     end
#   end

  def your_mobile_tribe
    mobile_client_link = link_to_function("<div>#{image_tag('mt_logo.png')}<span class='text'>#{link_name(t("views.your_mobiletribe"))}</span></div>", "window.open('#{property(:mobile_client_link)}','','scrollbars=no,menubar=no,height=720,width=450,resizable=yes,toolbar=no,location=no,status=no');", :class=>"green-color green-link without_underline")
#    if !cookies["mt_client_link_click"].blank? && cookies["mt_client_link_click"] == "1"
      mobile_client_link
#     else
#       link_to("<div>#{image_tag('mt_logo.png')}<span class='text'>#{link_name(t("views.your_mobiletribe"))}</span></div>", mobile_tribe_description_support_path(:width => "500", :height=>"270"), :title => t("views.mobile_tribe_client.title"), :class=>"thickbox green-color green-link without_underline", :id => "mobile_client_id") +
#           javascript_tag(%Q!$("#mobile_client_id").click(function(event){
#             $(".mt_button").replaceWith(#{('<div class=\'mt_button\'>' + mobile_client_link + '</div>').to_json})
#           return false;
#           })!)
#           end
 end

          def help_system_window link = "#{property(:sp_help_url)}"
    "window.open('#{link}','','scrollbars=yes,menubar=no,height=700,width=950,resizable=yes,toolbar=no,location=no,status=no');"
  end

  def help_icon options = {}
    help_url = options[:url] || @help_url
    image = options[:image] || "info1.png"
    unless help_url.blank?
      "&nbsp;&nbsp;#{link_to_function(image_tag(image), help_system_window(help_url))}"
    else
      "&nbsp;"
    end
  end

  def application_help_icon(options = {})
    link_to(image_tag("info1.png"), "#TB_inline?height=220&width=550&inlineId=#{options[:description_id]}", :class => "thickbox application_help_icon")
  end

  def html_description(description)
    #content = ""
    description.is_a?(Array) ? description.join("<br/> ")  : description.to_yaml.sub(/^---\s*/m, "").gsub(/\n/, "<br/> ").gsub(/\s/, "&nbsp;")
    #puts description.to_json.to_s
#    description.each do |k,v|
#      content << "<br/><b>#{k.to_s.capitalize}</b><br/>"
#      if v.is_a?(Hash)
#        v = v.map do |e|
#          "#{e[0].to_s.capitalize.humanize}:&nbsp;#{e[1].is_a?(Hash) || e[1].is_a?(Array) ? e[1].map.join(":&nbsp;") : e[1]}"
#        end
#      end
#      v.each { |el| content << "&nbsp;&nbsp;#{el}<br/>" }
#    end unless description.blank?
    #content
  end

  def string_description(description)
    content = ""
    description.each do |k,v|
      content << "#{k.to_s.capitalize}: "
      v = v.map{|e| e.join(": ")} if v.is_a?(Hash)
      content << v.join("; ")
    end unless description.blank?
    content
  end

  def user_profile_friend_link user, friend
    title, link = if user.active_friend?(friend)
                    [t("views.delete_from_friends"), friendship_delete_user_path(user, :friend_id => friend.id)]
                  elsif user.pending_friend?(friend)
                     if user.incoming_friend_request_from?(friend)
                       [t("views.users.friendship_request_pending"), incoming_requests_user_friendships_path(user)]
                     else
                       [t("views.delete_invitation"), friendship_delete_user_path(user, :friend_id => friend.id)]
                    end
                  elsif !user.friend?(friend) || user.reject_friend?(friend)
                    [t("views.add_as_friend"), friendship_request_user_path(user, :friend_id => friend.id)]
                  else
                    [t("views.add_as_friend"), friendship_request_user_path(user, :friend_id => friend.id)]
                  end
    link_to(wide_button(title), link, :class=>"standart-button")
  end
  
    def collection_checks(name, collection, values, options = {}, &block)
    check_boxes = []
    collection.each do |choice|
      text = choice.last
      value = choice.first
      id = [name.to_s, value.to_s.underscore].join('_')
      label_with_input = content_tag(:label,
        check_box_tag("#{name}[]",
          value,
          [values].flatten.include?(value.to_s),
          options.merge(:id => id)) +
        " #{text}",
        :for => id
      )
      if block_given?
        yield label_with_input
      else
        check_boxes << content_tag(:li, label_with_input)
      end
    end
    content_tag(:ul, check_boxes) unless block_given?
  end

  def country_list

  end
  def no_items_title(msg)
    content_tag(:h2, msg, :class => 'no_items') unless msg.blank?
  end
  
  def time_zones
    [
["(GMT-08:00) Pacific Time", "GMT-08:00"],      
["(GMT-12:00) Eniwetok, Kwajalein", "GMT-12:00"], 
["(GMT-11:00) Midway Island, Samoa", "GMT-11:00"],
["(GMT-10:00) Hawaii", "GMT-10:00"],
["(GMT-09:00) Alaska", "GMT-09:00"],
["(GMT-08:00) Pacific Time", "GMT-08:00"],
["(GMT-07:00) Mountain Time US & Canada)", "GMT-07:00"],
["(GMT-06:00) Central Time US & Canada), Mexico City", "GMT-06:00"],
["(GMT-05:00) Eastern Time US &amp; Canada), Bogota, Lima", "GMT-05:00"],
["(GMT-04:00) Atlantic Time Canada), Caracas, La Paz", "GMT-04:00"],
["(GMT-03:30) Newfoundland", "GMT-03:30"],
["(GMT-03:00) Brazil, Buenos Aires, Georgetown", "GMT-03:00"],                                
["(GMT-02:00) Mid-Atlantic", "GMT-02:00"],
["(GMT-01:00) Azores, Cape Verde Islands", "GMT-01:00"],
["(GMT+00:00) Western Europe Time, London, Lisbon, Casablanca", "GMT+00:00"],
["(GMT+01:00) Brussels, Copenhagen, Madrid, Paris", "GMT+01:00"],
["(GMT+02:00) Kaliningrad, South Africa", "GMT+02:00"],
["(GMT+03:00) Baghdad, Riyadh, Moscow, St. Petersburg", "GMT+03:00"],
["(GMT+03:30) Tehran", "GMT+03:30"],
["(GMT+04:00) Abu Dhabi, Muscat, Baku, Tbilisi", "GMT+04:00"],
["(GMT+04:30) Kabul", "GMT+04:30"],
["(GMT+05:00) Ekaterinburg, Islamabad, Karachi, Tashkent", "GMT+05:00"],
["(GMT+05:30) Bombay, Calcutta, Madras, New Delhi", "GMT+05:30"],
["(GMT+05:45) Kathmandu", "GMT+05:45"],
["(GMT+06:00) Almaty, Dhaka, Colombo", "GMT+06:00"],
["(GMT+07:00) Bangkok, Hanoi, Jakarta", "GMT+07:00"],
["(GMT+08:00) Beijing, Perth, Singapore, Hong Kong", "GMT+08:00"],
["(GMT+09:00) Tokyo, Seoul, Osaka, Sapporo, Yakutsk", "GMT+09:00"],
["(GMT+09:30) Adelaide, Darwin", "GMT+09:30"],
["(GMT+10:00) Eastern Australia, Guam, Vladivostok", "GMT+10:00"],
["(GMT+11:00) Magadan, Solomon Islands, New Caledonia", "GMT+11:00"],
["(GMT+12:00) Auckland, Wellington, Fiji, Kamchatka", "GMT+12:00"]
]
  end

  def user_title 
 [
   ["Mr","Mr"],
   ["Ms","Ms"],
   ["Dr","Dr"]
 ]
 
end
 
  
def enterprise_locale
    [
["en", "en"],
["zh", "zh"],
["aa", "aa"],
["ab", "ab"],
["ae", "ae"],
["af", "af"],
["ak", "ak"],
["am", "am"],
["an", "an"],
["ar", "ar"],
["as", "as"],
["av", "av"],
["ay", "ay"],
["az", "az"],
["ba", "ba"],
["be", "be"],
["bg", "bg"],
["bh", "bh"],
["bi", "bi"],
["bm", "bm"],
["bn", "bn"],
["bo", "bo"],
["br", "br"],
["bs", "bs"],
["ca", "ca"],
["ce", "ce"],
["ch", "ch"],
["co", "co"],
["cr", "cr"],
["cs", "cs"],
["cu", "cu"],
["cv", "cv"],
["cy", "cy"],
["da", "da"],
["de", "de"],
["dv", "dv"],
["dz", "dz"],
["ee", "ee"],
["el", "el"],
["eo", "eo"],
["es", "es"],
["et", "et"],
["eu", "eu"],
["fa", "fa"],
["ff", "ff"],
["fi", "fi"],
["fj", "fj"],
["fo", "fo"],
["fr", "fr"],
["fy", "fy"],
["ga", "ga"],
["gd", "gd"],
["gl", "gl"],
["gn", "gn"],
["gu", "gu"],
["gv", "gv"],
["ha", "ha"],
["he", "he"],
["hi", "hi"],
["ho", "ho"],
["hr", "hr"],
["ht", "ht"],
["hu", "hu"],
["hy", "hy"],
["hz", "hz"],
["ia", "ia"],
["id", "id"],
["ie", "ie"],
["ig", "ig"],
["ii", "ii"],
["ik", "ik"],
["in", "in"],
["io", "io"],
["is", "is"],
["it", "it"],
["iu", "iu"],
["iw", "iw"],
["ja", "ja"],
["ji", "ji"],
["jv", "jv"],
["ka", "ka"],
["kg", "kg"],
["ki", "ki"],
["kj", "kj"],
["kk", "kk"],
["kl", "kl"],
["km", "km"],
["kn", "kn"],
["ko", "ko"],
["kr", "kr"],
["ks", "ks"],
["ku", "ku"],
["kv", "kv"],
["kw", "kw"],
["ky", "ky"],
["la", "la"],
["lb", "lb"],
["lg", "lg"],
["li", "li"],
["ln", "ln"],
["lo", "lo"],
["lt", "lt"],
["lu", "lu"],
["lv", "lv"],
["mg", "mg"],
["mh", "mh"],
["mi", "mi"],
["mk", "mk"],
["ml", "ml"],
["mn", "mn"],
["mo", "mo"],
["mr", "mr"],
["ms", "ms"],
["mt", "mt"],
["my", "my"],
["na", "na"],
["nb", "nb"],
["nd", "nd"],
["ne", "ne"],
["ng", "ng"],
["nl", "nl"],
["nn", "nn"],
["no", "no"],
["nr", "nr"],
["nv", "nv"],
["ny", "ny"],
["oc", "oc"],
["oj", "oj"],
["om", "om"],
["or", "or"],
["os", "os"],
["pa", "pa"],
["pi", "pi"],
["pl", "pl"],
["ps", "ps"],
["pt", "pt"],
["qu", "qu"],
["rm", "rm"],
["rn", "rn"],
["ro", "ro"],
["ru", "ru"],
["rw", "rw"],
["sa", "sa"],
["sc", "sc"],
["sd", "sd"],
["se", "se"],
["sg", "sg"],
["si", "si"],
["sk", "sk"],
["sl", "sl"],
["sm", "sm"],
["sn", "sn"],
["so", "so"],
["sq", "sq"],
["sr", "sr"],
["ss", "ss"],
["st", "st"],
["su", "su"],
["sv", "sv"],
["sw", "sw"],
["ta", "ta"],
["te", "te"],
["tg", "tg"],
["th", "th"],
["ti", "ti"],
["tk", "tk"],
["tl", "tl"],
["tn", "tn"],
["to", "to"],
["tr", "tr"],
["ts", "ts"],
["tt", "tt"],
["tw", "tw"],
["ty", "ty"],
["ug", "ug"],
["uk", "uk"],
["ur", "ur"],
["uz", "uz"],
["ve", "ve"],
["vi", "vi"],
["vo", "vo"],
["wa", "wa"],
["wo", "wo"],
["xh", "xh"],
["yi", "yi"],
["yo", "yo"],
["za", "za"],
["zu", "zu"]
   ]
  end
  
  
   def enterprise_language
    [
	["English","English"],
	["Afrikaans","Afrikaans"],
	["Albanian","Albanian"],
	["Amharic","Amharic"],
	["Arabic","Arabic"],
	["Armenian","Armenian"],
	["Azeri","Azeri"],
	["Bengali","Bengali"],
	["Belorussian","Belorussian"],
	["Bosnian","Bosnian"],
	["Burmese","Burmese"],
	["Bulgarian","Bulgarian"],
	["Cambodian","Cambodian"],
	["Chinese","Chinese"],
	["Creole","Creole"],
	["Croatian","Croatian"],
	["Czech","Czech"],
	["Danish","Danish"],
	["Dutch","Dutch"],
	["English","English"],
	["Estonian","Estonian"],
	["Ethiopian","Ethiopian"],
	["Farsi","Farsi"],
	["Finnish","Finnish"],
	["Flemish","Flemish"],
	["French","French"],
	["Georgian","Georgian"],
	["German","German"],
	["Greek","Greek"],
	["Gujarati","Gujarati"],
	["Hebrew, Yiddish","Hebrew, Yiddish"],
	["Hindi","Hindi"],
	["Hungarian","Hungarian"],
	["Indonesian","Indonesian"],
	["Italian","Italian"],
	["Japanese","Japanese"],
	["Kazakh","Kazakh"],
	["Korean","Korean"],
	["Lao","Lao"],
	["Latvian","Latvian"],
	["Lithuanian","Lithuanian"],
	["Macedonian","Macedonian"],
	["Malay","Malay"],
	["Maltese","Maltese"],
	["Norwegian","Norwegian"],
	["Pangasinan","Pangasinan"],
	["Polish","Polish"],
	["Portuguese","Portuguese"],
	["Punjabi","Punjabi"],
	["Romanian","Romanian"],
	["Russian","Russian"],
	["Serbian","Serbian"],
	["Sinhalese","Sinhalese"],
	["Slovak","Slovak"],
	["Slovene","Slovene"],
	["Somali","Somali"],
	["Spanish","Spanish"],
	["Swahili","Swahili"],
	["Swedish","Swedish"],
	["Tagalog","Tagalog"],
	["Tajik","Tajik"],
	["Tatar","Tatar"],
	["Tamil","Tamil"],
	["Thai","Thai"],
	["Turkish","Turkish"],
	["Turkmen","Turkmen"],
	["Ukrainian","Ukrainian"],
	["Urdu","Urdu"],
	["Uzbek","Uzbek"],
	["Vietnamese","Vietnamese"],
	["Xhosa","Xhosa"],
	["Zulu","Zulu"]
  ]
  end
  
  
  
def enterprise_countries
  [
	["United States", "United States"],
	["Canada", "Canada"],
	["United Kingdom", "United Kingdom"],
	["Albania", "Albania"],
	["Algeria", "Algeria"],
	["Argentina", "Argentina"],
	["Australia", "Australia"],
	["Austria", "Austria"],
	["Bahrain", "Bahrain"],
	["Belarus", "Belarus"],
	["Belgium", "Belgium"],
	["Bolivia", "Bolivia"],
	["Bosnia and Herzegovina", "Bosnia and Herzegovina"],
	["Brazil", "Brazil"],
	["Bulgaria", "Bulgaria"],
	["Chile", "Chile"],
	["China", "China"],
	["Colombia", "Colombia"],
	["Costa Rica", "Costa Rica"],
	["Croatia", "Croatia"],
	["Cyprus", "Cyprus"],
	["Czech Republic", "Czech Republic"],
	["Denmark", "Denmark"],
	["Dominican Republic", "Dominican Republic"],
	["Ecuador", "Ecuador"],
	["Egypt", "Egypt"],
	["El Salvador", "El Salvador"],
	["Estonia", "Estonia"],
	["Finland", "Finland"],
	["France", "France"],
	["Germany", "Germany"],
	["Greece", "Greece"],
	["Guatemala", "Guatemala"],
	["Honduras", "Honduras"],
	["Hong Kong", "Hong Kong"],
	["Hungary", "Hungary"],
	["Iceland", "Iceland"],
	["India", "India"],
	["Indonesia", "Indonesia"],
	["Iraq", "Iraq"],
	["Ireland", "Ireland"],
	["Israel", "Israel"],
	["Italy", "Italy"],
	["Japan", "Japan"],
	["Jordan", "Jordan"],
	["Kuwait", "Kuwait"],
	["Latvia", "Latvia"],
	["Lebanon", "Lebanon"],
	["Libya", "Libya"],
	["Lithuania", "Lithuania"],
	["Luxembourg", "Luxembourg"],
	["Macedonia", "Macedonia"],
	["Malaysia", "Malaysia"],
	["Malta", "Malta"],
	["Mexico", "Mexico"],
	["Montenegro", "Montenegro"],
	["Morocco", "Morocco"],
	["Netherlands", "Netherlands"],
	["New Zealand", "New Zealand"],
	["Nicaragua", "Nicaragua"],
	["Norway", "Norway"],
	["Oman", "Oman"],
	["Panama", "Panama"],
	["Paraguay", "Paraguay"],
	["Peru", "Peru"],
	["Philippines", "Philippines"],
	["Poland", "Poland"],
	["Portugal", "Portugal"],
	["Puerto Rico", "Puerto Rico"],
	["Qatar", "Qatar"],
	["Romania", "Romania"],
	["Russia", "Russia"],
	["Saudi Arabia", "Saudi Arabia"],
	["Serbia and Montenegro", "Serbia and Montenegro"],
	["Serbia", "Serbia"],
	["Singapore", "Singapore"],
	["Slovakia", "Slovakia"],
	["Slovenia", "Slovenia"],
	["South Africa", "South Africa"],
	["South Korea", "South Korea"],
	["Spain", "Spain"],
	["Sudan", "Sudan"],
	["Sweden", "Sweden"],
	["Switzerland", "Switzerland"],
	["Syria", "Syria"],
	["Taiwan", "Taiwan"],
	["Thailand", "Thailand"],
	["Tunisia", "Tunisia"],
	["Turkey", "Turkey"],
	["Ukraine", "Ukraine"],
	["United Arab Emirates", "United Arab Emirates"],
	["Uruguay", "Uruguay"],
	["Venezuela", "Venezuela"],
	["Vietnam", "Vietnam"],
	["Yemen", "Yemen"]
 ]
end



def callcontrol_number
  [
    ["1111-222-33","1111-222-33"],
    ["1111-222-53","1111-222-53"],
    ["1111-222-43","1111-222-43"],
    ["1111-222-63","1111-222-63"]
  ]
end

  def country_phone_code
    [
      ["+1", "+1"],
=begin
# edited by jhlee on 20120525
      ["+1-242", "+1-242"],
      ["+1-246", "+1-246"],
      ["+1-264", "+1-264"],
      ["+1-268", "+1-268"],
      ["+1-284", "+1-284"],
      ["+1-345", "+1-345"],
      ["+1-441", "+1-441"],
      ["+1-473", "+1-473"],
      ["+1-649", "+1-649"],
      ["+1-664", "+1-664"],
      ["+1-670", "+1-670"],
      ["+1-671", "+1-671"],
      ["+1-684", "+1-684"],
      ["+1-758", "+1-758"],
      ["+1-767", "+1-767"],
      ["+1-784", "+1-784"],
      ["+1-787 and 1-939", "+1-787 and 1-939"],
      ["+1-809 and 1-829", "+1-809 and 1-829"],
      ["+1-868", "+1-868"],
      ["+1-869", "+1-869"],
      ["+1-876", "+1-876"],
=end
      ["+20", "+20"],
      ["+212", "+212"],
      ["+213", "+213"],
      ["+216", "+216"],
      ["+218", "+218"],
      ["+220", "+220"],
      ["+221", "+221"],
      ["+222", "+222"],
      ["+223", "+223"],
      ["+224", "+224"],
      ["+225", "+225"],
      ["+226", "+226"],
      ["+227", "+227"],
      ["+228", "+228"],
      ["+229", "+229"],
      ["+230", "+230"],
      ["+231", "+231"],
      ["+232", "+232"],
      ["+233", "+233"],
      ["+234", "+234"],
      ["+235", "+235"],
      ["+236", "+236"],
      ["+237", "+237"],
      ["+238", "+238"],
      ["+239", "+239"],
      ["+240", "+240"],
      ["+241", "+241"],
      ["+242", "+242"],
      ["+243", "+243"],
      ["+244", "+244"],
      ["+245", "+245"],
      ["+246", "+246"],
      ["+248", "+248"],
      ["+249", "+249"],
      ["+250", "+250"],
      ["+251", "+251"],
      ["+252", "+252"],
      ["+253", "+253"],
      ["+254", "+254"],
      ["+255", "+255"],
      ["+256", "+256"],
      ["+257", "+257"],
      ["+258", "+258"],
      ["+260", "+260"],
      ["+261", "+261"],
      ["+262", "+262"],
      ["+263", "+263"],
      ["+264", "+264"],
      ["+265", "+265"],
      ["+266", "+266"],
      ["+267", "+267"],
      ["+268", "+268"],
      ["+269", "+269"],
      ["+27", "+27"],
      ["+290", "+290"],
      ["+291", "+291"],
      ["+30", "+30"],
      ["+31", "+31"],
      ["+32", "+32"],
      ["+33", "+33"],
      ["+34", "+34"],
      ["+350", "+350"],
      ["+351", "+351"],
      ["+352", "+352"],
      ["+353", "+353"],
      ["+354", "+354"],
      ["+355", "+355"],
      ["+356", "+356"],
      ["+357", "+357"],
      ["+358", "+358"],
      ["+359", "+359"],
      ["+36", "+36"],
      ["+370", "+370"],
      ["+371", "+371"],
      ["+372", "+372"],
      ["+373", "+373"],
      ["+374", "+374"],
      ["+375", "+375"],
      ["+376", "+376"],
      ["+377", "+377"],
      ["+378", "+378"],
      ["+379", "+379"],
      ["+380", "+380"],
      ["+381", "+381"],
      ["+382", "+382"],
      ["+385", "+385"],
      ["+386", "+386"],
      ["+387", "+387"],
      ["+389", "+389"],
      ["+39", "+39"],
      ["+40", "+40"],
      ["+41", "+41"],
      ["+420", "+420"],
      ["+421", "+421"],
      ["+423", "+423"],
      ["+43", "+43"],
      ["+44", "+44"],
      ["+45", "+45"],
      ["+46", "+46"],
      ["+47", "+47"],
      ["+48", "+48"],
      ["+49", "+49"],
      ["+500", "+500"],
      ["+501", "+501"],
      ["+502", "+502"],
      ["+503", "+503"],
      ["+504", "+504"],
      ["+505", "+505"],
      ["+506", "+506"],
      ["+507", "+507"],
      ["+508", "+508"],
      ["+509", "+509"],
      ["+51", "+51"],
      ["+52", "+52"],
      ["+53", "+53"],
      ["+54", "+54"],
      ["+55", "+55"],
      ["+56", "+56"],
      ["+57", "+57"],
      ["+58", "+58"],
      ["+590", "+590"],
      ["+591", "+591"],
      ["+592", "+592"],
      ["+593", "+593"],
      ["+595", "+595"],
      ["+597", "+597"],
      ["+598", "+598"],
      ["+60", "+60"],
      ["+61", "+61"],
      ["+62", "+62"],
      ["+63", "+63"],
      ["+64", "+64"],
      ["+65", "+65"],
      ["+66", "+66"],
      ["+670", "+670"],
      ["+672", "+672"],
      ["+673", "+673"],
      ["+674", "+674"],
      ["+675", "+675"],
      ["+676", "+676"],
      ["+677", "+677"],
      ["+678", "+678"],
      ["+679", "+679"],
      ["+680", "+680"],
      ["+681", "+681"],
      ["+682", "+682"],
      ["+683", "+683"],
      ["+685", "+685"],
      ["+686", "+686"],
      ["+687", "+687"],
      ["+688", "+688"],
      ["+689", "+689"],
      ["+690", "+690"],
      ["+691", "+691"],
      ["+692", "+692"],
      ["+7", "+7"],
      ["+81", "+81"],
      ["+82", "+82"],
      ["+84", "+84"],
      ["+850", "+850"],
      ["+852", "+852"],
      ["+855", "+855"],
      ["+856", "+856"],
      ["+86", "+86"],
      ["+880", "+880"],
      ["+886", "+886"],
      ["+90", "+90"],
      ["+91", "+91"],
      ["+92", "+92"],
      ["+93", "+93"],
      ["+94", "+94"],
      ["+95", "+95"],
      ["+960", "+960"],
      ["+961", "+961"],
      ["+962", "+962"],
      ["+963", "+963"],
      ["+964", "+964"],
      ["+965", "+965"],
      ["+966", "+966"],
      ["+967", "+967"],
      ["+968", "+968"],
      ["+971", "+971"],
      ["+972", "+972"],
      ["+973", "+973"],
      ["+974", "+974"],
      ["+975", "+975"],
      ["+976", "+976"],
      ["+977", "+977"],
      ["+98", "+98"],
      ["+992", "+992"],
      ["+993", "+993"],
      ["+994", "+994"],
      ["+995", "+995"],
      ["+996", "+996"],
      ["+998", "+998"]
    ]
  end
end

def currency_list
  [
    ["USD","USD"],
    ["GBP","GBP"],
    ["CNY","CNY"],
    ["EUR","EUR"]
  ]
end


  def user_profile_employee_link user
    title, link = [t("views.add_as_employee"), new_recruit_employees_path(:user_id => user)]
    link_to(wide_button(title), link, :class=>"standart-button")
  end

	def client_browser_name 
		user_agent = request.env['HTTP_USER_AGENT'].downcase 
		if user_agent =~ /msie/i 
			"IE" 
		elsif user_agent =~ /konqueror/i 
			"Konqueror" 
		elsif user_agent =~ /gecko/i 
			"Mozilla" 
		elsif user_agent =~ /opera/i 
			"Opera" 
		elsif user_agent =~ /applewebkit/i 
			"Safari" 
		else 
			"Unknown" 
		end 
	end 
	
	def check_user_ippbx?
		success = false
		if property(:use_ippbx)
			success = true
		end
		return success
	end
 
	def check_company_ippbx?
		success = false
		if property(:use_ippbx)
			success = true
		end
		return success
	end


# STATS

	def get_total(table, date_from, date_to)

		if table == "payments"
			field = "transaction_date"
		else
			field = "created_at"
		end

		if date_from!="" && date_to!=""
			if table=="payments"
				where_clause = "WHERE #{field} BETWEEN '#{date_from}' AND '#{date_to}' AND transaction_type='subscr_signup'"
			else
				where_clause = "WHERE #{field} BETWEEN '#{date_from}' AND '#{date_to}'"
			end
		else
			if table=="payments"
				where_clause = "WHERE transaction_type='subscr_signup'"
			else
				where_clause = ""
			end
		end

		query = "SELECT count(*) as cnt FROM #{table} #{where_clause}"
		#logger.info "get_total query: #{query}"

		ret = 0
		result_set = ActiveRecord::Base.connection.execute(query) 
		
		if !result_set.blank?
			result_set.each do |row|
				ret =row[0]
			end
		end
		return ret
		
	end

	def get_daily_stats(table, date_from, date_to)

		if table == "payments"
			field = "transaction_date"
		else
			field = "created_at"
		end

		if date_from!="" && date_to!=""
			if table=="payments"
				where_clause = "WHERE #{field} BETWEEN '#{date_from} 00:00:00' AND '#{date_to} 23:59:59' AND transaction_type='subscr_signup'"
			else
				where_clause = "WHERE #{field} BETWEEN '#{date_from} 00:00:00' AND '#{date_to} 23:59:59'"
			end
		else
			if table=="payments"
				where_clause = "WHERE transaction_type='subscr_signup'"
			else
				where_clause = ""
			end
		end
		
		query = "SELECT date(#{field}) as daily, count(*) as num FROM #{table} #{where_clause} GROUP BY daily ORDER BY daily ASC"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
#   while row = result_set.fetch_row do
#				logger.info "row[0]: #{row[0]}"
#				logger.info "row[1]: #{row[1]}"
#   end
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end
	
	
	def get_hourly_stats(table, date_from, date_to)

		if table == "payments"
			field = "transaction_date"
		else
			field = "created_at"
		end

		where_clause = ""
		if date_from!="" && date_to!=""
			if table=="payments"
				where_clause = "WHERE #{field} BETWEEN '#{date_from} 00:00:00' AND '#{date_to} 23:59:59' AND transaction_type='subscr_signup'"
			else
				where_clause = "WHERE #{field} BETWEEN '#{date_from} 00:00:00' AND '#{date_to} 23:59:59'"
			end
		elsif(date_from)
			date_to = datefrom + "23:59:59" 
			if table=="payments"
				where_clause = "WHERE #{field} BETWEEN '#{date_from} 00:00:00' AND '#{date_to}' AND transaction_type='subscr_signup'"
			else
				where_clause = "WHERE #{field} BETWEEN '#{date_from} 00:00:00' AND '#{date_to}'"
			end
		end
		
		query = "SELECT DATE_FORMAT(#{field},'%Y-%m-%d %H') as hourly, count(*) as num FROM #{table} #{where_clause} GROUP BY hourly ORDER BY hourly ASC"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new
		
		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end

	def latest_date(table)

		if table == "payments"
			field = "transaction_date"
		else
			field = "created_at"
		end

		query = "SELECT #{field} FROM #{table} ORDER BY #{field} DESC LIMIT 1"
		result_set = ActiveRecord::Base.connection.execute(query) 
		ret = ""
		if !result_set.blank?
			result_set.each do |row|
				ret =row
			end
		end
		return ret
	end

	def get_date(table, order)
		if table == "payments"
			field = "transaction_date"
		else
			field = "created_at"
		end

		query = "SELECT #{field} FROM #{table} ORDER BY #{field} #{order} LIMIT 1"
		result_set = ActiveRecord::Base.connection.execute(query) 
		ret = ""
		
		if !result_set.blank?
			result_set.each do |row|
				ret =row
			end
		end
		
		return ret
	end

	def get_total_apps()
		query = "SELECT a.name as name, count(*) as num FROM applications a JOIN companifications c ON a.id=c.application_id GROUP BY c.application_id"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
#   while row = result_set.fetch_row do
#				logger.info "row[0]: #{row[0]}"
#				logger.info "row[1]: #{row[1]}"
#   end
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end

	def get_companies_by_employee()
		query = "SELECT size, count(*) as num FROM linkedin_companies GROUP BY size"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				if row[0]==""
					ret["not specified"] = row[1]
				else
					ret[row[0]] = row[1]
				end
			end
		end
		return ret
	end

	def get_companies_by_country()
		query = "SELECT country, count(*) as num FROM linkedin_companies GROUP BY country"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				if row[0]==""
					ret["not specified"] = row[1]
				else
					ret[row[0]] = row[1]
				end
			end
		end

		return ret
	end

	def get_companies_by_industry()
		query = "SELECT i.industry as industry, count(*) as num FROM linkedin_companies c JOIN linkedin_industries i ON c.industry=i.code GROUP BY c.industry"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end

	def get_founders_by_employee()
		query = "SELECT c.size, count(*) as num FROM linkedin_users u JOIN linkedin_companies c ON u.login=c.linkedin GROUP BY c.size"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end
		return ret
	end

	def get_founders_by_country()
		query = "SELECT c.country, count(*) as num FROM linkedin_users u JOIN linkedin_companies c ON u.login=c.linkedin GROUP BY c.country"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end

	def get_founders_by_industry()
		query = "SELECT i.industry as industry, count(*) as num FROM linkedin_users u JOIN linkedin_companies c ON u.login=c.linkedin JOIN linkedin_industries i ON c.industry=i.code GROUP BY c.industry"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end


def get_week_dates(yearweek, start = true)
	yearweek_array = yearweek.split("-")
	year = yearweek_array[0].to_i
	week = yearweek_array[1].to_i

	from = Date.commercial(year, week, 1).to_s #returns the date of monday in week
	to  =  Date.commercial(year, week, 7).to_s #returns the date of sunday in week

	if(start)
		return from
	else 
		return to
	end
end

def get_month_info(month, year)
	if Date.leap?(year.to_i)
		day = 29
	else
		day = 28
	end
	month_array = Array.new
	month_array[0] = nil
	month_array[1] = {"01" => 31}
	month_array[2] = {"02" => day}
	month_array[3] = {"03" => 31}
	month_array[4] = {"04" => 30}
	month_array[5] = {"05" => 31}
	month_array[6] = {"06" => 30}
	month_array[7] = {"07" => 31}
	month_array[8] = {"08" => 31}
	month_array[9] = {"09" => 30}
	month_array[10] = {"10" => 31}
	month_array[11] = {"11" => 30}
	month_array[12] = {"12" => 31}

	return month_array[month]
end

def get_year_month_info(yearmonth)
	year_month_array = yearmonth.split("-")
	year = year_month_array[0]
	month = year_month_array[1]

	#logger.info"year: #{year}"
	#logger.info"month: #{month}"

	if Date.leap?(year.to_i)
		day = 29
	else
		day = 28
	end

	year_month_arrays = {"#{year}-01" => 31, "#{year}-02" => day, "#{year}-03" => 31, "#{year}-04" => 30, "#{year}-05" => 31, "#{year}-06" => 30, "#{year}-07" => 31, "#{year}-08" => 31, "#{year}-09" => 30, "#{year}-10" => 31, "#{year}-11" => 30, "#{year}-12" => 31}
	#logger.info"year_month_arrays: #{year_month_arrays.to_json}"

	return year_month_arrays[yearmonth].to_s
end

def get_dates(first, last)
	first_date = Date.parse(first)
	last_date = Date.parse(last)

	ret = (first_date..last_date).to_a

	return ret
end


def get_date_hours(first,last)
	require 'date'

	ret =Array.new
	first_year, first_month, first_day = first.split("-")
	last_year, last_month, last_day = last.split("-")
	i = Date.new(first_year.to_i,first_month.to_i,first_day.to_i).to_time.to_i
	j = DateTime.new(last_year.to_i,last_month.to_i,last_day.to_i, 23,59,59).to_time.to_i
	
	while i < j + 1
		ret << Time.at(i).strftime("%Y-%m-%d %H")
		i +=3600
	end

	return ret
end

	def urlencode(plaintext)
		CGI.escape(plaintext.to_s).gsub("+", "%20").gsub("%7E", "~")
	end

	def generate_csv(type, data, heading)
		require 'date'
		if type=="daily_registered" || type=="daily_paid"
			datetime = Time.new.strftime("%Y-%m-%d")
		elsif type=="hourly_registered"  || type=="hourly_paid"
			datetime = Time.new.strftime("%Y-%m-%d_%H")
		end
		filename = "#{RAILS_ROOT}/public/resources/"+type+"_"+datetime+".csv"
		if !FileTest.exist?(filename)
			File.open(filename, 'w') do |f|
				f.puts heading
				data.each do |k,v|
					f.puts k + "," + v.to_s
				end
			end
		end
	end

=begin
	def shorten(str, count) 
		logger.info "str.length: #{str.length} and count: #{count}"
		if str.length > count
			#ret = str.first(count) + '... '
			ret = str.gsub(/^(.{count}\S*).+$/s,'\1') + '... '
		else
			ret = str
		end
		#ret = str.gsub(/^(.{"+count+"}\S*).+$/s,'\1')
		return ret
	end
=end


# COMPANY STATS

=begin
	def company_apps(company_id)
		query = "SELECT a.name FROM companifications c JOIN applications a ON c.application_id=a.id WHERE c.company_id='#{company_id}' AND c.status='paid'"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Array.new
		#ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret << row[0]
			end
		end
		#ret = Hash[*ret1]
		return ret
	end
=end

	def company_apps(company_id)
		query = "SELECT a.id, a.name FROM companifications c JOIN applications a ON c.application_id=a.id WHERE c.company_id='#{company_id}' AND c.status='paid'"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end

	def get_paid_month(company_id)
		query = "SELECT DATE_FORMAT(p.transaction_date, '%Y-%m') AS ym FROM payments p JOIN application_plans a ON p.plan_ids=a.id WHERE p.company_id='#{company_id}' AND p.transaction_type IN ('subscr_payment','onetime_payment') GROUP BY YEAR(transaction_date), MONTH(transaction_date) ORDER BY ym ASC"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Array.new
		#ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret << row[0]
			end
		end
		#ret = Hash[*ret1]
		return ret
	end

	def company_apps_total_cost(company_id)
		query = "SELECT a.name, REPLACE(FORMAT(SUM(p.amount),2),',','') AS amount FROM payments p JOIN application_plans ap ON p.plan_ids=ap.id JOIN applications a ON a.id=ap.application_id WHERE p.company_id='#{company_id}' AND p.transaction_type IN ('subscr_payment','onetime_payment') GROUP BY p.plan_ids"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end

	def company_top_apps_by_cost(company_id)
		query = "SELECT a.name, REPLACE(FORMAT(SUM(p.amount),2),',','') AS amount FROM payments p JOIN application_plans ap ON p.plan_ids=ap.id JOIN applications a ON a.id=ap.application_id WHERE p.company_id='#{company_id}' AND p.transaction_type IN ('subscr_payment','onetime_payment') GROUP BY p.plan_ids ORDER BY SUM(p.amount) DESC LIMIT 5"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end

	def department_top_apps_by_cost(company_id) # too many join clause; need to separate
		query = "SELECT d.name, REPLACE(FORMAT(SUM(p.amount),2),',','') AS amount FROM payments p JOIN application_plans ap ON p.plan_ids=ap.id JOIN applications a ON a.id=ap.application_id JOIN department_applications da ON da.application_id= a.id JOIN departments d ON d.id=da.department_id WHERE p.company_id='#{company_id}' AND p.transaction_type IN ('subscr_payment','onetime_payment') AND d.company_id='#{company_id}' GROUP BY p.plan_ids"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end

	def employee_top_apps_by_cost(company_id) 
		query = "SELECT e.user_id, REPLACE(FORMAT(SUM(p.amount),2),',','') AS amount FROM payments p JOIN application_plans ap ON p.plan_ids=ap.id JOIN applications a ON a.id=ap.application_id JOIN employee_applications ea ON ea.application_id= a.id JOIN employees e ON e.id=ea.employee_id WHERE p.company_id='#{company_id}' AND e.company_id='#{company_id}' AND p.transaction_type IN ('subscr_payment','onetime_payment') group by e.id"

		result_set = ActiveRecord::Base.connection.execute(query) 
		ret ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				ret[row[0]] = row[1]
			end
		end

		return ret
	end
