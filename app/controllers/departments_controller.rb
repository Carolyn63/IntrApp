class DepartmentsController < ApplicationController
  before_filter :require_user
  before_filter :find_company

  def create
    unless params[:department].blank?
	  department_params = []
	  create_params = []
	  @departments = []
	
	  params[:department].each_with_index do |d, index|
	    department_params[index] = d.last
	  end

	  params[:department].each_with_index do |d, index|
	    department = Department.find_by_id(d.first.split('_').last)
	    unless department.nil?
	      unless department_params[index].blank?
		department.update_attribute(:name, department_params[index])
	      else
		@company.departments_attributes = [{ :id => department.id, '_destroy' => '1'}]
		@company.save
	      end
	    else
	      create_params << department_params[index]
	    end
	  end

	  create_params.each_with_index do |d, index|
	    @departments[index] = {:name => create_params[index]}
	  end

	  if @company.update_attributes( :departments_attributes => @departments)
	    @departments = @company.departments.all
	    render :update do |page|
	      page["error"].hide
	      page["message"].slideToggle('slow')
	      page["loading_indicator"].hide
	      page["departments_fields"].replace_html :partial => "departments/form"
	    end
	  end
    else
       render :update do |page|
	      page["message"].hide
	      page["error"].slideToggle('slow')
	      page["loading_indicator"].hide
	      page["departments_fields"].replace_html :partial => "departments/form"
       end
    end
  end

  protected
  
  def find_company
    @company = current_user.companies.find_by_id params[:company_id]
    report_maflormed_data if @company.blank?
  end
end
