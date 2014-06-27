require 'net/http'
require 'rubygems'
require 'json'

  
class ApplicationController < ActionController::Base
  
  helper :all # include all helpers, all the time
  helper_method :current_user_session, :current_user, :help_url, :current_own_company, :current_employee, :linkedin_signup, :linkedin_signin, :do_login

  include ExceptionNotification::Notifiable
  include SortableTable::App::Controllers::ApplicationController

  # Protects the user sessions from being spoofed
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Actions to be performed before the controller is loaded
  before_filter :require_only_active
  before_filter :help_system_url

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation

  # Prettifies the pagination
  begin
    WillPaginate::ViewHelpers.pagination_options[:previous_label] = I18n.t("views.pagination_prev")
    WillPaginate::ViewHelpers.pagination_options[:next_label] = I18n.t("views.pagination_next")
  rescue => e
  end
  
  def do_login(member_id)
    user_id = ""
	user3p = User3p.find_by_member_id(member_id)
	unless user3p.blank?
		logger.info("User3p ID#{user3p.id}")
		user = User.find_by_id(user3p.user_id)
		unless user.blank?
			@user_session = UserSession.new(:login=> user.login, :password => Tools::AESCrypt.new.decrypt(user.user_password))
			@user_session.save do |result|
			if result
				  user = User.find_by_username_or_email(@user_session.login)
				  user_id = user.id
			end	
			end
		end
	end	
	user_id
  end

  def user_admin_login_required
 logger.info("session name/.........#{session[:user_admin]}")
			logger.info("session pass........#{session[:user_pass]}")
    if session[:user_admin] and session[:user_pass]
    return true
    end
    session[:user_return_to]=request.request_uri
    redirect_to  useradmin_logins_path
    return false
  end

  def ent_admin_login_required    
    if session[:ent_admin] and session[:ent_pass]
    return true
    end
    session[:ent_return_to]=request.request_uri
    redirect_to  entadmin_logins_path
    return false
  end

  def sp_admin_login_required    
    if session[:sp_admin] and session[:sp_pass]
    return true
    end
    session[:sp_return_to]=request.request_uri
    redirect_to  spadmin_logins_path
    return false
  end

  def sys_admin_login_required
    #session[:sys_admin] = nil
    #logger.info "sys_admin_login_required session sys_user #{session[:sys_admin]}"
    #logger.info "sys_admin_login_required session sys_pass #{session[:sys_pass]}"
    if session[:sys_admin] and session[:sys_pass]
    return true
    end
    session[:sys_return_to] = request.request_uri
    redirect_to  sysadmin_logins_path
    return false
  end

  # If any bad data is entered into a message, then this method will report it
  # back to the user.
  def report_maflormed_data(message = nil)
    flash[:error] = message || t("controllers.bad_data")
    redirect_to(root_path) and return
  end

  # If there is a problem with the APIs integrated into the site, this method
  # will report it back to the user and throw them back to the index page.
  def report_integrate_problem
    flash[:error] = t("controllers.problem_with_ondeego_request")
    redirect_to(root_path) and return
  end
   def current_own_company
    @current_own_company ||= current_user.companies.first
  end
  protected

  def require_only_active
    if !current_user.blank? && !current_user.status_active?      
      current_user_session.destroy
      if current_user.blocked?
        flash[:error] = t("controllers.your_account_blocked")
      elsif current_user.status_unconfirmed?
        flash[:error] = t("controllers.your_account_uncomfirmed")
        
      end
      redirect_back_or_default root_path
    end
  end

  # Defines what should happen if the user enters an area that is meant for
  # users with the administrators role.
  def admin_only
    if !current_user.blank? && !current_user.admin?
    flash[:error] = t("controllers.access_denied")
    redirect_to root_path
    end
  end
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  # Defines who the current user is. If no user is defined, the method pulls
  # the data from the current user session. If no user is present, then the
  # <code>current_user</code> variable is rendered empty.
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end
  


  def current_employee
    @current_employee ||= current_user.first_active_employee
  end

  def current_employee?; current_employee.present?; end

  def current_user_company
    @current_user_company ||= current_user.try(:first_active_employee).try(:company)
  end

  def current_user_company?; current_user_company.present?; end

  # Defines what should happen to people who need to be logged in to see
  # a certain area of the site.
  #
  # Authenticates over a simple HTTP request with the username and the
  # password.
  def require_user
    unless current_user
      respond_to do |format|
        format.html do
          store_location
          flash[:notice] = t("controllers.you_must_be_logged")
          redirect_to new_user_session_url
          return false
        end
        format.any(:xml, :json) do
          authenticate_or_request_with_http_basic do |username, password|
            @user_session = UserSession.new(:login => username, :password => password)
            @user_session.save
          end
        end
      end
    end
  end
  
  # Checks users or company can use ippbx service
	def check_user_ippbx
		success = false
		if property(:use_ippbx)
			success = true
		else
			message =  t("controllers.ippbx_disabled") 
		end
		if !success
			flash[:error] = "#{t("controllers.access_denied")}.  #{message}"
			redirect_to root_path
		end
		return success
	end
 
	def check_company_ippbx
		success = false
		if property(:use_ippbx)
			success = true
		else
			message =  t("controllers.ippbx_disabled") 
		end
		if !success
			flash[:error] = "#{t("controllers.access_denied")}.   #{message}"
			redirect_to root_path
		end
		return success
	end
  
  # Defines what happens if the user enters an area that requires no login
  def require_no_user
    if current_user
    #For fix of nested flash
    #store_location
    flash[:notice] = t("controllers.you_must_be_logged_out")
    redirect_to root_url
    return false
    end
  end

  # Stores the last location that the user has visited in their own session
  # variable.
  def store_location
    session[:return_to] = request.request_uri
  end

  # Either redirect the user back to the last page they visited, or to a
  # defined location stated in the +default+ variable.
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def check_services email,user_id
	  payments = Payment.find_last_by_email(email)
	  if !payments.blank?
	  company_services = CompanyService.find_all_by_payment_id_and_user_id(payments.id, user_id)
	  services = Service.find(:all)
	  
	  services.each do |service|
		session_name = "use_" + service.service_code
		session[session_name] = false
	  end
	 
	  company_services.each do |company_service|
		  logger.info(company_service.service.name)
		  services.each do |service|
			if company_service.service.name == service.name
				session_name = "use_" + service.service_code
				logger.info(session_name)
				if (company_service.paid == 0 && payments.transaction_type == "subscr_signup" ) || company_service.paid == 1
					session[session_name] = true
				else
					session[session_name] = false
				end
				
			end
		  end
	  end
	  end
  
  logger.info(".......#{session["use_ippbx"]}")
  end  

def linkedin_signup
logger.info("Setting Session>>>>>>>")
session[:linkedin_signup] = true
if session[:linkedin_signup]
logger.info("Yes>>>>>>>>>>>>>>>>>>")
end
end

def linkedin_signin
logger.info("LInkedin Signin>>>>>>>")
session[:linkedin_signin] = true
end

  def check_company_services user_id
   logger.info("owner service check...............")
   user = User.find_by_id(user_id)
   is_owner = user.owner_companies?
   if !user.employees[0].blank? or is_owner
    if is_owner
      owner = user
    else
      company = Company.find_by_id(user.employees[0].company_id)
      owner = User.find_by_id(company.user_id)
    end
    services = Service.find(:all)
    services.each do |service|
      company_session_name = "use_company_" + service.service_code
      session_name = "use_" + service.service_code
      session[session_name] = false
      session[company_session_name] = false
      company_service = CompanyService.find_by_user_id_and_service_id(owner.id,service.id)
      if !company_service.blank?
      grace_period = DateTime.parse("2012-05-05 01:09:05") + 7.days
      if (company_service.paid == 0 && company_service.subscription_type == "subscr_signup" ) || company_service.paid == 1  || (company_service.subscription_type == "subscr_cancel" and graceperiod > Time.now)
        session[session_name] = true
        if is_owner
          session[company_session_name] = true
          logger.info("owner service paid..........")
        end
      end 
      end
    end
  
    end

 end
  
  
  
  def help_system_url
    @help_url = HelpUrl.find_help_url(params.merge(:url_params => request.query_string))
  end

  def addslash(str)
    return str.to_s.gsub(/['"\\\x0]/,'\\\\\0')
  end

  def generate_password( len )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("2".."9").to_a
    pass = ""
    1.upto(len) { |i| pass << chars[rand(chars.size-1)] }
    return pass
  end
  
  def generate_login(email)
      login = "default_user"
      unless email.blank?
		  login = email.split("@")[0].downcase
		  unless login.blank?
		  for i in 1..1000
			if User.find_by_login(login).blank?
			break
			else
			login = login + i.to_s
			end
		  end
		  end
	  end
	  return login 
  end
  

  def remove_space(fields)
      strip_field = fields.inject({}) {|h, (k,v)| h.update({k=>v.strip()})}
      return strip_field
  end
  
  def titelize_all fields, keys
    ret[] = ""
    unless keys.blank?
    stripped_fields = fields.inject({}) {|h, (k,v)| h.update({k=>v.strip()})}
    except_fields = stripped_fields.except(*keys)
    not_except_fields = stripped_fields.slice(*keys)
    titlized_field = except_fields.inject({}) {|h, (k,v)| h.update({k=>v.titleize()})}
    ret = not_except_fields.deep_merge(titlized_field)
    end 
    return ret
  end
end

def from_country_code(code)
 country_codes = {
'AF'=>'Afghanistan',
'AL'=>'Albania',
'DZ'=>'Algeria',
'AS'=>'American Samoa',
'AD'=>'Andorra',
'AO'=>'Angola',
'AI'=>'Anguilla',
'AQ'=>'Antarctica',
'AG'=>'Antigua And Barbuda',
'AR'=>'Argentina',
'AM'=>'Armenia',
'AW'=>'Aruba',
'AU'=>'Australia',
'AT'=>'Austria',
'AZ'=>'Azerbaijan',
'BS'=>'Bahamas',
'BH'=>'Bahrain',
'BD'=>'Bangladesh',
'BB'=>'Barbados',
'BY'=>'Belarus',
'BE'=>'Belgium',
'BZ'=>'Belize',
'BJ'=>'Benin',
'BM'=>'Bermuda',
'BT'=>'Bhutan',
'BO'=>'Bolivia',
'BA'=>'Bosnia And Herzegovina',
'BW'=>'Botswana',
'BV'=>'Bouvet Island',
'BR'=>'Brazil',
'IO'=>'British Indian Ocean Territory',
'BN'=>'Brunei',
'BG'=>'Bulgaria',
'BF'=>'Burkina Faso',
'BI'=>'Burundi',
'KH'=>'Cambodia',
'CM'=>'Cameroon',
'CA'=>'Canada',
'CV'=>'Cape Verde',
'KY'=>'Cayman Islands',
'CF'=>'Central African Republic',
'TD'=>'Chad',
'CL'=>'Chile',
'CN'=>'China',
'CX'=>'Christmas Island',
'CC'=>'Cocos (Keeling) Islands',
'CO'=>'Columbia',
'KM'=>'Comoros',
'CG'=>'Congo',
'CK'=>'Cook Islands',
'CR'=>'Costa Rica',
'CI'=>'Ivory Coast',
'HR'=>'Croatia (Hrvatska)',
'CU'=>'Cuba',
'CY'=>'Cyprus',
'CZ'=>'Czech Republic',
'CD'=>'Democratic Republic Of Congo (Zaire)',
'DK'=>'Denmark',
'DJ'=>'Djibouti',
'DM'=>'Dominica',
'DO'=>'Dominican Republic',
'TP'=>'East Timor',
'EC'=>'Ecuador',
'EG'=>'Egypt',
'SV'=>'El Salvador',
'GQ'=>'Equatorial Guinea',
'ER'=>'Eritrea',
'EE'=>'Estonia',
'ET'=>'Ethiopia',
'FK'=>'Falkland Islands (Malvinas)',
'FO'=>'Faroe Islands',
'FJ'=>'Fiji',
'FI'=>'Finland',
'FR'=>'France',
'FX'=>'France, Metropolitan',
'GF'=>'French Guinea',
'PF'=>'French Polynesia',
'TF'=>'French Southern Territories',
'GA'=>'Gabon',
'GM'=>'Gambia',
'GE'=>'Georgia',
'DE'=>'Germany',
'GH'=>'Ghana',
'GB'=>'United Kingdom',
'GI'=>'Gibraltar',
'GR'=>'Greece',
'GL'=>'Greenland',
'GD'=>'Grenada',
'GP'=>'Guadeloupe',
'GU'=>'Guam',
'GT'=>'Guatemala',
'GN'=>'Guinea',
'GW'=>'Guinea-Bissau',
'GY'=>'Guyana',
'HT'=>'Haiti',
'HM'=>'Heard And McDonald Islands',
'HN'=>'Honduras',
'HK'=>'Hong Kong',
'HU'=>'Hungary',
'IS'=>'Iceland',
'IN'=>'India',
'ID'=>'Indonesia',
'IR'=>'Iran',
'IQ'=>'Iraq',
'IE'=>'Ireland',
'IL'=>'Israel',
'IT'=>'Italy',
'JM'=>'Jamaica',
'JP'=>'Japan',
'JO'=>'Jordan',
'KZ'=>'Kazakhstan',
'KE'=>'Kenya',
'KI'=>'Kiribati',
'KW'=>'Kuwait',
'KG'=>'Kyrgyzstan',
'LA'=>'Laos',
'LV'=>'Latvia',
'LB'=>'Lebanon',
'LS'=>'Lesotho',
'LR'=>'Liberia',
'LY'=>'Libya',
'LI'=>'Liechtenstein',
'LT'=>'Lithuania',
'LU'=>'Luxembourg',
'MO'=>'Macau',
'MK'=>'Macedonia',
'MG'=>'Madagascar',
'MW'=>'Malawi',
'MY'=>'Malaysia',
'MV'=>'Maldives',
'ML'=>'Mali',
'MT'=>'Malta',
'MH'=>'Marshall Islands',
'MQ'=>'Martinique',
'MR'=>'Mauritania',
'MU'=>'Mauritius',
'YT'=>'Mayotte',
'MX'=>'Mexico',
'FM'=>'Micronesia',
'MD'=>'Moldova',
'MC'=>'Monaco',
'MN'=>'Mongolia',
'MS'=>'Montserrat',
'MA'=>'Morocco',
'MZ'=>'Mozambique',
'MM'=>'Myanmar (Burma)',
'NA'=>'Namibia',
'NR'=>'Nauru',
'NP'=>'Nepal',
'NL'=>'Netherlands',
'AN'=>'Netherlands Antilles',
'NC'=>'New Caledonia',
'NZ'=>'New Zealand',
'NI'=>'Nicaragua',
'NE'=>'Niger',
'NG'=>'Nigeria',
'NU'=>'Niue',
'NF'=>'Norfolk Island',
'KP'=>'North Korea',
'MP'=>'Northern Mariana Islands',
'NO'=>'Norway',
'OM'=>'Oman',
'PK'=>'Pakistan',
'PW'=>'Palau',
'PA'=>'Panama',
'PG'=>'Papua New Guinea',
'PY'=>'Paraguay',
'PE'=>'Peru',
'PH'=>'Philippines',
'PN'=>'Pitcairn',
'PL'=>'Poland',
'PT'=>'Portugal',
'PR'=>'Puerto Rico',
'QA'=>'Qatar',
'RE'=>'Reunion',
'RO'=>'Romania',
'RU'=>'Russia',
'RW'=>'Rwanda',
'SH'=>'Saint Helena',
'KN'=>'Saint Kitts And Nevis',
'LC'=>'Saint Lucia',
'PM'=>'Saint Pierre And Miquelon',
'VC'=>'Saint Vincent And The Grenadines',
'SM'=>'San Marino',
'ST'=>'Sao Tome And Principe',
'SA'=>'Saudi Arabia',
'SN'=>'Senegal',
'SC'=>'Seychelles',
'SL'=>'Sierra Leone',
'SG'=>'Singapore',
'SK'=>'Slovak Republic',
'SI'=>'Slovenia',
'SB'=>'Solomon Islands',
'SO'=>'Somalia',
'ZA'=>'South Africa',
'GS'=>'South Georgia And South Sandwich Islands',
'KR'=>'South Korea',
'ES'=>'Spain',
'LK'=>'Sri Lanka',
'SD'=>'Sudan',
'SR'=>'Suriname',
'SJ'=>'Svalbard And Jan Mayen',
'SZ'=>'Swaziland',
'SE'=>'Sweden',
'CH'=>'Switzerland',
'SY'=>'Syria',
'TW'=>'Taiwan',
'TJ'=>'Tajikistan',
'TZ'=>'Tanzania',
'TH'=>'Thailand',
'TG'=>'Togo',
'TK'=>'Tokelau',
'TO'=>'Tonga',
'TT'=>'Trinidad And Tobago',
'TN'=>'Tunisia',
'TR'=>'Turkey',
'TM'=>'Turkmenistan',
'TC'=>'Turks And Caicos Islands',
'TV'=>'Tuvalu',
'UG'=>'Uganda',
'UA'=>'Ukraine',
'AE'=>'United Arab Emirates',
'UK'=>'United Kingdom',
'US'=>'United States',
'UM'=>'United States Minor Outlying Islands',
'UY'=>'Uruguay',
'UZ'=>'Uzbekistan',
'VU'=>'Vanuatu',
'VA'=>'Vatican City (Holy See)',
'VE'=>'Venezuela',
'VN'=>'Vietnam',
'VG'=>'Virgin Islands (British)',
'VI'=>'Virgin Islands (US)',
'WF'=>'Wallis And Futuna Islands',
'EH'=>'Western Sahara',
'WS'=>'Western Samoa',
'YE'=>'Yemen',
'YU'=>'Yugoslavia',
'ZM'=>'Zambia',
'ZW'=>'Zimbabwe'
}

return country_codes[code]
end

	def require_https 
		#redirect_to :protocol => "https://" unless (request.ssl? or local_request?) 
		redirect_to({:protocol => "https"}.merge(:params => request.query_parameters)) unless (request.ssl? or local_request?) 
	end 

	def require_http
		redirect_to :protocol => "http://" if (request.ssl?) 
	end
