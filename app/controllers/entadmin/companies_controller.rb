class Entadmin::CompaniesController  < Entadmin::ResourcesController
  sortable_attributes :name, :email, :extn, :workphone
  def index
    redirect_to employees_entadmin_company_path(session[:ent_company_id])
    logger.info("company id......."+session[:ent_company_id].to_s)
  end

  def employees
    if params[:firstName].empty? and params[:lastName].empty? and params[:emailId].empty?
    @employees = resource.employees.by_status("active").paginate :page => params[:page], :include => :user
    elsif !params[:firstName].empty?
    logger.info("FirstName Parameter ...."+params[:firstName])
    @employees=Employee.find_by_sql "select * from employees e join users u on e.user_id = u.id where u.firstname regexp '"+params[:firstName]+"' and e.company_id = '"+session[:ent_company_id].to_s+"'"
    elsif !params[:lastName].empty?
    logger.info("FirstName Parameter ...."+params[:firstName])
    @employees=Employee.find_by_sql "select * from employees e join users u on e.user_id = u.id where u.lastname regexp '"+params[:lastName]+"' and e.company_id = '"+session[:ent_company_id].to_s+"'"
    elsif !params[:emailId].empty?
      logger.info("email id" +params[:emailId])
    @employees=Employee.find_by_sql "select * from employees e join users u on e.user_id = u.id where u.email regexp '"+params[:emailId]+"' and e.company_id='"+session[:ent_company_id].to_s+"'"
    end
  end

end
