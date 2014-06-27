class SearchController < ApplicationController
  auto_complete_for :user, [:firstname, :lastname], :sphinx_search_by => [:name], :sphinx_filter => [:sphinx_public_and_coworkers, :current_user]

  auto_complete_for :user, :firstname,     :sphinx_search_by => [:firstname], :sphinx_filter => [:sphinx_public_and_coworkers, :current_user]
  auto_complete_for :user, :lastname,      :sphinx_search_by => [:lastname], :sphinx_filter => [:sphinx_public_and_coworkers, :current_user]
  auto_complete_for :user, :email,         :sphinx_search_by => [:email], :sphinx_filter => [:sphinx_public_and_coworkers, :current_user]
  auto_complete_for :user, :login,         :sphinx_search_by => [:login], :sphinx_filter => [:sphinx_public_and_coworkers, :current_user]
  auto_complete_for :user, :phone,         :sphinx_search_by => [:phone], :sphinx_filter => [:sphinx_public_and_coworkers, :current_user]
  auto_complete_for :user, :address,       :sphinx_search_by => [:address], :sphinx_filter => [:sphinx_public_and_coworkers, :current_user]
  auto_complete_for :user, :job_title,     :sphinx_search_by => [:job_title], :sphinx_filter => [:sphinx_public_and_coworkers, :current_user]
  auto_complete_for :user, :description,   :sphinx_search_by => [:description], :sphinx_filter => [:sphinx_public_and_coworkers, :current_user]

  auto_complete_for :company, :name,         :sphinx_search_by => [:name], :sphinx_filter => [:sphinx_public_and_employers, :current_user]

  auto_complete_for :company, :address,      :sphinx_search_by => [:address], :sphinx_filter => [:sphinx_public_and_employers, :current_user]
  auto_complete_for :company, :phone,        :sphinx_search_by => [:phone], :sphinx_filter => [:sphinx_public_and_employers, :current_user]
  auto_complete_for :company, :company_type, :sphinx_search_by => [:company_type], :sphinx_filter => [:sphinx_public_and_employers, :current_user]
  auto_complete_for :company, :description,  :sphinx_search_by => [:description], :sphinx_filter => [:sphinx_public_and_employers, :current_user]
  auto_complete_for :company, :industry,     :sphinx_search_by => [:industry], :sphinx_filter => [:sphinx_public_and_employers, :current_user]

  before_filter :require_user
  
  def users
    filters = params[:company_id].blank? ? {} : {:company_id => params[:company_id]}
    @users = User.public_and_coworkers(current_user).by_first_letter(params[:search]).paginate(:page => params[:page], :order =>"firstname ASC")
    @companies = [[]] + Company.by_public_and_employers(current_user).all(:limit => 100).map{|c| [c.name, c.id]}
  end

  def companies
    @companies = Company.by_public_and_employers(current_user).by_first_letter(params[:search]).paginate(:page => params[:page], :order => params[:sort_by] ? params[:sort_by] : "name" + " ASC")
  end

end
