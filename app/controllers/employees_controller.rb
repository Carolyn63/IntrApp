class EmployeesController < PortalIppbxController
  before_filter :require_user, :except => [:invitation]
  before_filter :find_company, :except => [:people, :new_recruit, :recruit, :invitation, :company_department, :check_email_name]
  before_filter :only_owner, :only => [:index, :new, :edit, :create, :update, :invite, :invite_all, :destroy]
  before_filter :find_employee, :only => [:invite, :destroy, :edit, :update, :sogo_connect, :edit_by_employee, :update_by_employee, :devices, :update_devices]
  before_filter :fill_user_companies, :only => [:new_recruit, :recruit]
  before_filter :find_prev, :only => [:new_recruit, :recruit]

  def index
    params[:status] ||= Employee::Status::ACTIVE
    @employees = @company.employees.by_status(params[:status]).paginate :page => params[:page], :include => :user
  end

  def new
    @user = User.new
    @employee = @user.employees.build
  end

  def new_bulk
  end

  def create
    params[:employee] = remove_space(params[:employee])
    params[:user] = remove_space(params[:user])
    success = false
    success, @user, @employee = Employee.create_employee_by_company params 
    if success 
      flash[:notice]  = t("controllers.employee_created")
      unless @employee.send_invitation.to_i.zero?
        @employee.deliver_invite!
        flash[:notice] += "<br/>" + t("controllers.invitation_sent")
      end
      redirect_to company_employees_path(@company.id)
    else
      flash.now[:error]  = t("controllers.employee_create_failed")
      render :action => "new"
    end
  end

	def bulk_create
		if params[:user][:bulk_csv_file].blank? or (params[:user][:bulk_csv_file].content_type != "text/plain" and params[:user][:bulk_csv_file].content_type != "application/vnd.ms-excel")
			flash.now[:error]  = t("controllers.upload_csv")
			render :action => "new_bulk"
		else
			require "faster_csv"
			#csv = FasterCSV.new(params[:user][:bulk_csv_file])
			logger.info "content type: #{params[:user][:bulk_csv_file].content_type}"

			filename =  params[:user][:bulk_csv_file].original_filename
			directory = "public/data/csv/#{params[:user][:company_id]}"
			# create the directory
			Dir.mkdir(directory) unless File.directory?(directory)
			# create the file path
			path = File.join(directory, filename)
			# write the file
			File.open(path, "wb") do |f| 
				f.write(params[:user][:bulk_csv_file].read)
			end
			#render :action => "new_bulk"

			#logger.info "csv: #{csv.to_json}"

			params[:user][:bulk_csv_file] = nil

			#validate csv
			i, j, k = 0, 0, 0
			FasterCSV.foreach(path, :headers => true) do |row|
			#csv.each do |row|
				if row[0] == "email address"
					next
				end
				email = row[0]
				fname = row[1]
				lname = row[2]
				if email.blank? or email !~ /^[A-Z0-9_\.%\+\-]+@(?:[A-Z0-9\-]+\.)+(?:[A-Z]{2,4})$/i
					i += 1
					break
				end
				if fname.blank?
					j += 1
					break
				end
				if lname.blank?
					k += 1
					break
				end
			end
			
			if i != 0
				flash.now[:error]  = t("controllers.malformed_email_format")
				render :action => "new_bulk"
			elsif j != 0
				flash.now[:error]  = t("controllers.firstname_format")
				render :action => "new_bulk"
			elsif k != 0
				flash.now[:error]  = t("controllers.lastname_format")
				render :action => "new_bulk"
			else
				logger.info "path: #{path}"
				#create users, employees
				l = 0
				FasterCSV.foreach(path, :headers => true) do |row|
				#csv.each do |row|
					if row[0] == "email address"
						next
					end
					params[:user][:email] = row[0]
					params[:user][:firstname] = row[1]
					params[:user][:lastname] = row[2]
					user = User.find_by_email(params[:user][:email])

					if user.blank?
						params[:user][:login] = generate_login(params[:user][:email]) + params[:user][:company_id].to_s
						logger.info ("params user: #{params[:user].to_json}")

						params[:employee] = Hash.new
						logger.info "make_active: #{params[:user][:make_active]}"

						if params[:user][:make_active].to_i==1
							params[:employee][:status] = "active"
						end

						params[:employee][:company_id] = params[:user][:company_id]
						params[:employee][:company_email] = params[:user][:login] + "@" + property(:sogo_email_domain)
						logger.info ("params employee: #{params[:employee].to_json}")
						success = false
						success, @user, @employee = Employee.create_employee_by_company params 
						if success 
							@employee.deliver_invite!
						else
							l += 1
						end
					else
						logger.info "user: #{user.id}"
					end
				end
				#csv.close

				if l == 0 
					flash[:notice]  = t("controllers.bulk_employees_created")
					redirect_to company_employees_path(@company.id)
				else
					flash.now[:error]  = t("controllers.bulk_employee_create_failed")
					render :action => "new_bulk"
				end
			end
		end
	end

  def edit
  end

  def update
    success = false
    if @employee.update_attributes(params[:employee])
        flash[:notice] = t("controllers.employee_updated")
        redirect_to company_employees_path(@company.id, :status => params[:status])
    else
      flash.now[:error]  = t("controllers.employee_update_failed")
      render :action => "edit"
    end
  end

  def show

  end

#  def edit_company_email
#    render :layout => false
#  end
#
#  def update_company_email
#    success = @employee.update_attributes(params[:employee])
#    render :update do |page|
#      if success
#        page.call "tb_remove"
#        page.redirect_to user_employers_path(current_user.id, :status => Employee::Status::ACTIVE)
#      else
#        page["edit_company_email"].replace_html :partial => "edit_company_email"
#      end
#    end
#  end

  def edit_by_employee
    render :layout => false
  end

  def update_by_employee
    success = @employee.update_attributes(params[:employee])
    render :update do |page|
      if success
        page.call "tb_remove"
        page.redirect_to user_employers_path(current_user.id, :status => Employee::Status::ACTIVE)
      else
        page["edit_by_employee"].replace_html :partial => "edit_by_employee"
      end
    end
  end
  
  #Appstore Update
  def devices
  end
  
  def update_devices
    if @employee.update_attributes(:device_ids => params[:device_ids])
      flash[:notice] = t("controllers.employee_device_updated")
      redirect_to devices_company_employee_path(@company, @employee)
    else
      flash.now[:error]  = t("controllers.employee_device_update_failed")
      render :action => "devices"
    end
  end
  #TRAC 202 - Controllers - Employees_Controller - New_Recruit
  #
  # Adds conditional to fixes done to the recruitment process. 

  def new_recruit

    # Does two things- looks up the user via an id sent via Get, then checks
    # to see if a company exists.
    # The first check ensures we have a user, and the second ensures that only
    # company owners can use this function.

    @user = User.find_by_id(params[:user_id])
    report_maflormed_data if @user.blank?
    @company = current_user.companies.first   
    flash[:error] = t("controllers.not_any_company") and redirect_to(root_path) if @company.blank?
    
    # Will correctly delete a rejected employee of a company by ensuring that
    # the company is specified at the time of the delete request.
    # prior to this, the portal assumed that the employee only had one
    # request. This approach should ensure that the beginnings of a
    # multi-company approach is set up.
    current_user.delete_exist_rejected_employee_of_user(@user, @company)
  end

  #TRAC 202 - Controllers - Employees_Controller - Recruit
  #
  # Adds conditionals for reverting back to the recruitment stage without its fixes.

  def recruit
    @user = User.find_by_id params[:user_id]
    @company = current_user.companies.find_by_id(params[:company_id])
    report_maflormed_data if @company.blank? || @user.blank?

    @employee = Employee.new(params[:employee])
    @employee.company_pending = 1
    @employee.company = @company
    @employee.user = @user
    if @employee.save
      flash[:notice]  = t("controllers.employee_created")
      unless @employee.send_invitation.to_i.zero?
        @employee.deliver_invite!
        flash[:notice] += "<br/>" + t("controllers.invitation_sent")
      end
  #      flash[:notice]  = t("controllers.employee_recruited")
  #      @employee.deliver_invite! unless @employee.send_invitation.to_i.zero?
      redirect_to users_path
    else
      flash.now[:error]  = t("controllers.employee_recruit_failed")
      render :action => "new_recruit"
    end
  end

  def company_department
    @company = current_user.companies.find_by_id(params[:company_id])
    render :update do |page|
      unless @company.blank?
        page["company_department"].replace_html(:partial => "company_department", :locals => {:company => @company})
        page["company_department_loader"].hide();
        page["company_department"].show();
      else
        page.alert(t("controllers.bad_data"))
      end
    end
  end

  def check_email_name
    email = Employee.add_company_email_domain(params[:email_name])
		logger.info "email: #{email}, #{params[:email_name]}"
    email_name_used = !Employee.find_by_company_email(email).blank?
    render :update do |page|
      if email_name_used
        new_email_name = Employee.unique_email_name(email)
        page["email_already_used"].show();
        page["employee_company_email_name"].value = new_email_name;
        page["email_already_used_error"].replace_html(t("views.companies.email_already_taken_and_replaced",
                      :prev_email => email, :new_email => Employee.add_company_email_domain(new_email_name)));
      end
    end
  end

  def activate_all
		logger.info("employees params: #{params[:employees]}")

    Employee.activate_employees(@company, params["employees"]) unless params["employees"].blank?
    flash[:notice]  = t("controllers.activated")
    redirect_to company_employees_path(@company)
  end

  def invite_all
    Employee.invite_employees(@company, params["employees"]) unless params["employees"].blank?
    flash[:notice]  = t("controllers.invitation_sent")
    redirect_to company_employees_path(@company)
  end

  def invite
    @employee.deliver_invite!
    redirect_to company_employees_path(@company)
  end

  def destroy_all
    unless params["employees"].blank?
			if property(:use_ippbx)
				unless @company.ippbx.blank?
					redirect_to company_employees_path(@company) unless destroy_ippbx_user(params["employees"], @company.id)
				end
                        end
			unless @company.cloudstorage.blank?
				  PortalCloudstorageController.new.remove_employees(params["employees"])
			end
      not_destroy_employee = Employee.destroy_employees(@company, params["employees"])
      if not_destroy_employee.blank?
        flash[:notice]  = t("controllers.employee_successful_delete")
      else
        flash[:error]  = t("controllers.employees_delete_failed") + " #{not_destroy_employee.errors.on_base.blank? ? '' : not_destroy_employee.errors.on_base}"
      end
    end
    redirect_to company_employees_path(@company)
  end

  def destroy
    if @employee.destroy
      flash[:notice]  = t("controllers.employee_successful_delete")
    else
      flash[:error] = t("controllers.employee_delete_failed") + "#{@employee.errors.on_base.blank? ? '' : @employee.errors.on_base}"
    end
    redirect_to company_employees_path(@company)
  end

  def people
  end

  def invitation
    @employee = Employee.find_by_invitation_token(params[:invitation_token])
    unless @employee.blank?
      @user = @employee.user
      if @user.active
        @employee.reset_invitation_token!
        current_user_session.destroy if !current_user.blank? && current_user != @user
        redirect_to user_employers_path(@user)
      else
        @user.reset_perishable_token!
        current_user_session.destroy unless current_user.blank?
        redirect_to edit_password_reset_path(@user.perishable_token)
      end
    else
      redirect_to root_path
    end
  end

  def sogo_connect
    if @employee.sogo_connect!
      flash[:notice] = t("controllers.successful_connect_to_sogo")
      redirect_to user_employers_path(current_user.id, :status => Employee::Status::ACTIVE)
    else
      flash[:error] = t("controllers.error_connect_to_sogo") + "<br/> #{@employee.errors.full_messages.join("\n").gsub("\n", "<br/>")}"
      redirect_to user_employers_path(current_user.id, :status => Employee::Status::ACTIVE)
    end
  end

  protected

	def find_prev
		company = Employee.find_last_by_company_id_and_user_id_and_status(current_user.companies.first, params[:user_id], Employee::Status::PENDING)
		employee = Employee.find_by_user_id_and_status(params[:user_id], Employee::Status::ACTIVE)

		flash[:error] = t("controllers.employee_already_employee") and redirect_to(users_path) if(!employee.blank?)
		flash[:notice] = t("controllers.employee_invited_already") and redirect_to(users_path) if(!company.blank?)
	end

  def find_company
    @company = current_user.employers.find_by_id params[:company_id]
    report_maflormed_data if @company.blank?
  end

  def find_employee
    @employee = @company.employees.find_by_id params[:id]
    report_maflormed_data if @employee.blank?
  end

  def only_owner
    report_maflormed_data(t("controllers.access_denied")) unless @company.admin == current_user
  end

  def fill_user_companies
    @companies = current_user.companies.map{|c| [c.name, c.id]}
  end

  def htmlsafe(str)
     @escaped = URI::escape(str)
     return @escaped
  end

end
