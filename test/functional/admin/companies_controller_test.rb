require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/companies_controller'

# Re-raise errors caught by the controller.
class Admin::CompaniesController; def rescue_action(e) raise e end; end


class Admin::CompaniesControllerTest < ActionController::TestCase

  def setup
    @controller = Admin::CompaniesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "/admin/companies",           :action => :index
  should_route :get,  "/admin/companies/1",         :action => :show, :id => 1
  should_route :get,  "/admin/companies/new",       :action => :new
  should_route :post, "/admin/companies",           :action => :create
  should_route :get,  "/admin/companies/1/edit",    :action => :edit, :id => 1
  should_route :get,  "/admin/companies/1/employees",    :action => :employees, :id => 1

  context "Not logged in" do
    context "On get to :index" do
      setup{ get :index }
      should_respond_with :redirect
    end
  end

  context "Logged in as user" do
    setup do
      login_as users(:frai)
      get :index
    end
    should_respond_with :redirect
  end

  context "Logged in as admin" do
    setup do
      login_as users(:ben)
      @user = users(:ben)
      @company = @user.companies.first
      @employee = @company.employee(@user)
    end
    context "on GET to :index" do
      setup do
         get :index
      end
      should_respond_with :success
      should_assign_to :companies
      should_render_template :index
      should_not_set_the_flash
    end
    context "on GET to :index with filters" do
      setup do
         get :index, :privacy => @user.privacy
      end
      should_respond_with :success
      should_assign_to :companies
      should_render_template :index
      should_not_set_the_flash
      should "return right companies" do
        assert_equal assigns(:companies), [companies(:company_001)]
      end
    end
    context "on GET to :employees" do
      setup do
         get :employees, :id => @company.id
      end
      should_respond_with :success
      should_assign_to :employees
      should_assign_to :company
      should_render_template :employees
      should_not_set_the_flash
      should "return right employees" do
        assert_equal assigns(:employees), [employees(:employee_001), employees(:employee_002), employees(:employee_003)]
      end
    end
    context "on GET to :invite" do
      setup do
         get :invite, :id => @company.id, :employee_id => @employee.id
      end
      should_respond_with :redirect
      should_assign_to :employee
      should_assign_to :company
      should_set_the_flash_to :notice
    end
  end


end
