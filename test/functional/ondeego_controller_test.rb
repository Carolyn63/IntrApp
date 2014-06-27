require File.dirname(__FILE__) + '/../test_helper'
require 'ondeego_controller'

# Re-raise errors caught by the controller.
class OndeegoController; def rescue_action(e) raise e end; end

class OndeegoControllerTest < ActionController::TestCase

  def setup
    @controller = OndeegoController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "users/1/ondeego/login",           :action => :login, :controller => :ondeego, :user_id => "1"
  should_route :get,  "users/1/ondeego/company_create",  :action => :company_create, :controller => :ondeego, :user_id => "1"
  should_route :get,  "users/1/ondeego/employee_create", :action => :employee_create, :controller => :ondeego, :user_id => "1"

  context "Not logged in" do
    context "On get to :index" do
      setup{ get :index }
      should_respond_with :redirect
    end
  end

  context "Logged in" do
    context "use ondeego api" do
      setup do
        login_as users(:ben)
        @user = users(:ben)
        @company = @user.companies.first
        set_property(:use_ondeego, true)
      end
      teardown do
        set_property(:use_ondeego, false)
      end
      context "on GET to :company_create" do
        setup do
          get :company_create, :user_id => @user.id, :company_id => @company.id
        end
        should_assign_to :user
        should_assign_to :company
        should_assign_to :employee
        should_not_set_the_flash
        should_respond_with :success
        should_render_template :company_create
      end
      context "on GET to :employee_create" do
        setup do
          @employee = employees(:employee_002)
          get :employee_create, :user_id => @user.id, :company_id => @company.id
        end
        should_assign_to :user
        should_assign_to :company
        should_assign_to :employee
        should_assign_to :admin_employee
        should_not_set_the_flash
        should_respond_with :success
        should_render_template :employee_create
      end
      context "on GET to :employee_create with not connecting company" do
        setup do
          login_as users(:frai)
          @user = users(:frai)
          @company = companies(:company_003)
          Employee.any_instance.stubs(:ondeego_connect?).returns(false)
          get :employee_create, :user_id => @user.id, :company_id => @company.id
        end
        should_respond_with :redirect
        should_assign_to :company
        should_assign_to :user
        should_assign_to :admin_employee
      end
      context "on GET to :login" do
        setup do
          get :login, :user_id => @user.id, :company_id => @company.id
        end
        should_assign_to :user
        should_assign_to :company
        should_assign_to :employee
        should_not_set_the_flash
        should_respond_with :success
        should_render_template :login
      end
    end
    context "not use ondeego api" do
      setup do
        login_as users(:ben)
        @user = users(:ben)
        @company = @user.companies.first
      end
      context "on GET to :company_create" do
        setup do
          get :company_create, :user_id => @user.id, :company_id => @company.id
        end
        should_assign_to :user
        should_assign_to :company
        should_set_the_flash_to :notice
        should_respond_with :redirect
      end
      context "on GET to :employee_create" do
        setup do
          @employee = employees(:employee_002)
          get :employee_create, :user_id => @user.id, :company_id => @company.id
        end
        should_assign_to :user
        should_assign_to :company
        should_set_the_flash_to :notice
        should_respond_with :redirect
      end
      context "on GET to :login" do
        setup do
          get :login, :user_id => @user.id, :company_id => @company.id
        end
        should_assign_to :user
        should_assign_to :company
        should_set_the_flash_to :error
        should_respond_with :redirect
      end
    end
  end

end
