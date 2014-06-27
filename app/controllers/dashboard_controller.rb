class DashboardController < ApplicationController
  before_filter :require_user
  before_filter :find_user

  before_filter :require_https, :only => [:services, :payments]
  before_filter :require_http, :except => [:services, :payments] 

  def index
#    unless @user.blank?
#      #@companies = @user.companies.by_search(params[:search]).paginate :page => params[:page], :order => "name ASC"
#      @employers = @user.employers.by_search(params[:search]).active_and_pending_employers.paginate :page => 1, :order => "name DESC"
#    else
#
#    end

    #ApplicationController.session_options.update(:session_domain => property(:session_domain))
    #cookies["qd"] = {:domain => property(:session_domain), :value => "w1", :path => "/", :expires => 1.year.from_now}
    #p cookies
    #p cookies["qd"]
    #My Connection Request
    @employers_request = @user.employers.by_employee_status(Employee::Status::PENDING).all(:order => "employees.created_at DESC", :include => [:employees], :limit => 100)
    @friends_request = @user.incoming_requests.pending.all(:limit => 100)

    @employees_accepted_request = @user.accepted_published_contacts
    @friends_accepted_request = @user.accepted_published_friends
    @employees_accepted_request.each{|r| r.published! }
    @friends_accepted_request.each{|r| r.published! }
    
    #My Companies Profile
    @companies = @user.employers.active_employers.by_search(params[:search]).all(:order => "name ASC", :limit => 100)

    @recently_companies = Company.by_public_and_employers(current_user).all(:order => "companies.created_at DESC", :limit => 3)
    @recently_user = User.public_and_coworkers(current_user).all :order => "created_at DESC", :limit => 3
  end

  def ondeego_login_failed
    flash[:error] = t("controllers.appcentral_login_failed")
    redirect_to user_dashboard_index_path(current_user.id)
  end

  protected
  def find_user
    unless params[:user_id].blank?
      @user = User.find_by_id params[:user_id]
      report_maflormed_data unless @user == current_user
    end
  end

end
