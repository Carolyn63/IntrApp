require File.dirname(__FILE__) + '/../test_helper'
require 'employers_controller'

# Re-raise errors caught by the controller.
class EmployersController; def rescue_action(e) raise e end; end

class EmployersControllerTest < ActionController::TestCase

  def setup
    @controller = EmployersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "/users/1/employers",            :action => :index, :user_id => 1
  should_route :get,  "/users/1/employers/1/accept",   :action => :accept, :user_id => 1, :id => 1
  should_route :get,  "/users/1/employers/1/reject",   :action => :reject, :user_id => 1, :id => 1
  
  context "Not logged in" do
    context "On get to :index" do
      setup{ get :index }
      should_respond_with :redirect
    end
  end

  context "Logged in" do
    setup do
      @request.env["HTTP_REFERER"] = 'http://test.host/employees/'
      if property(:multi_company)
        @user = users(:user_3)
        @company = companies(:company_001)
      else
        @user = users(:user_4)
        @company = companies(:company_002)
      end
      login_as @user
      @employee = @company.employee(@user)
      @employee.update_attributes(:status => Employee::Status::PENDING)
      assert_not_nil @user
      assert_not_nil @company
      assert_not_nil @employee
    end
    context "on GET to :index" do
      setup do
         get :index, :user_id => @user.id
      end
       should_respond_with :success
       should_assign_to :user
       should_assign_to :employers
       should_render_template :index
       should_not_set_the_flash
       should "show company's employers" do
         assert_equal assigns(:employers), @user.employers.by_employee_status(Employee::Status::PENDING).paginate(:page => 1)
       end
    end
    context "on GET to :accept" do
      setup do
        put :accept, :user_id => @user.id, :id => @company.id
      end
       should_respond_with :redirect
       should_assign_to :company
       should_assign_to :user
       should_set_the_flash_to :notice
       should "accept employee" do
         assert assigns(:employee).active?
       end
    end
    context "on GET to :accept only for onw employers" do
      setup do
        put :accept, :user_id => @user.id, :id => companies(:company_003).id
      end
       should_respond_with :redirect
       should_set_the_flash_to :error
    end
    context "on GET to :reject" do
      setup do
        put :reject, :user_id => @user.id, :id => @company.id
      end
       should_respond_with :redirect
       should_assign_to :company
       should_assign_to :user
       #should_set_the_flash_to :notice
       should "show company's employers" do
         @employee.reload
         assert @employee.rejected?
       end
    end
    unless property(:multi_company)
      context "on GET to :accept with already exist active employee" do
        setup do
          @user = users(:ben)
          login_as @user
          @company = companies(:company_002)
          put :accept, :user_id => @user.id, :id => @company.id
        end
        should_respond_with :redirect
        should_assign_to :company
        should_assign_to :user
        should_assign_to :employee
        should_set_the_flash_to :error
      end
    end
  end
end
