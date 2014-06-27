require File.dirname(__FILE__) + '/../test_helper'
require 'departments_controller'

# Re-raise errors caught by the controller.
class DepartmentsController; def rescue_action(e) raise e end; end

class DepartmentsControllerTest < ActionController::TestCase

  def setup
    @controller = DepartmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :post,  "companies/1/departments", :controller => "departments",   :action => :create, :company_id => '1'

  context "Not logged in" do
    context "On get to :create" do
      setup{ get :create }
      should_respond_with :redirect
    end
  end

  context "Logged in" do
    setup do
      login_as users(:ben)
      @user = users(:ben)
      @company = @user.companies.first
      @department = departments(:department_001)
    end
    context "on GET to :create" do
      context "create departments" do
        setup do
          get :create, :company_id => @company.id, :department => {:name_1_0 => "first_department", :name_3_0 =>"second_department"}
        end
        should_respond_with :success
        should_not_set_the_flash
        should "create departments" do
          assert_equal assigns(:departments), @company.departments.all
        end
      end
      context "update departments" do
        setup do
          get :create, :company_id => @company.id, :department => {"name_1_#{@department.id}" => "update_department"}
        end
        should_respond_with :success
        should_not_set_the_flash
        should "update departments" do
          assert_equal assigns(:departments), @company.departments.all
        end
      end
      context "destroy departments" do
        setup do
          get :create, :company_id => @company.id, :department => {"name_1_#{@department.id}" => ""}
        end
        should_respond_with :success
        should_not_set_the_flash
        should "destroy departments" do
          assert_equal assigns(:departments), @company.departments.all
        end
      end

    end
  end
end
