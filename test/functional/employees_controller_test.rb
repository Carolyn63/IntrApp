require File.dirname(__FILE__) + '/../test_helper'
require 'employees_controller'

# Re-raise errors caught by the controller.
class EmployeesController; def rescue_action(e) raise e end; end

class EmployeesControllerTest < ActionController::TestCase

  def setup
    @controller = EmployeesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "/employees",           :action => :index
  should_route :get,  "/employees/1",         :action => :show, :id => 1
  should_route :get,  "/employees/new",       :action => :new
  should_route :post, "/employees",           :action => :create
  should_route :get,  "/employees/1/edit",    :action => :edit, :id => 1
  should_route :get,  "/companies/1/employees",        :action => :index, :company_id => 1
  should_route :get,  "/companies/1/employees/1",      :action => :show, :company_id => 1, :id => 1
  should_route :get,  "/companies/1/employees/new",    :action => :new, :company_id => 1
  should_route :post, "/companies/1/employees",        :action => :create, :company_id => 1
  should_route :get,  "/companies/1/employees/1/edit", :action => :edit, :company_id => 1, :id => 1
  should_route :get,  "/companies/1/employees/1/devices",   :action => :devices, :id => 1, :company_id => 1
  should_route :put, "/companies/1/employees/1/update_devices", :action => :update_devices, :id => 1, :company_id => 1

  should_route :get,  "/employees/new_recruit",   :action => :new_recruit
  should_route :post, "/employees/recruit",       :action => :recruit


  context "Not logged in" do
    context "On get to :index" do
      setup{ get :index }
      should_respond_with :redirect
    end
  end

  context "Logged in" do
    setup do
      login_as users(:ben)
      @user = users(:ben)
      @company = @user.companies.first
      @employee = employees(:employee_001)
    end
    context "on GET to :sogo_connect only employer company should be accessible" do
      setup do
         get :sogo_connect, :company_id => companies(:company_003).id, :id => employees(:employee_005).id
      end
      should_respond_with :redirect
      should_set_the_flash_to :error
    end
    context "on GET to :index" do
      setup do
         get :index, :company_id => @company.id
      end
       should_respond_with :success
       should_assign_to :company
       should_assign_to :employees
       should_render_template :index
       should_not_set_the_flash
       should "show company's employees" do
         assert_equal assigns(:employees), @company.employees.by_status(Employee::Status::ACTIVE).paginate(:page => 1)
       end
    end
    context "on GET to :index to other user employees" do
      setup do
        login_as users(:frai)
        get :index, :company_id => @company.id
      end
       should_respond_with :redirect
    end
    context "on GET to :index only active" do
      setup do
        get :index, :company_id => @company.id, :status => Employee::Status::ACTIVE
      end
       should_respond_with :success
       should_assign_to :company
       should_assign_to :employees
       should_render_template :index
       should_not_set_the_flash
       should "show company's employees" do
         assert_equal assigns(:employees).size, 2
         assert_equal assigns(:employees), @company.employees.by_status(Employee::Status::ACTIVE).paginate(:page => 1)
       end
    end
    context "on GET to :index only rejected" do
      setup do
        get :index, :company_id => @company.id, :status => Employee::Status::REJECTED
      end
       should_respond_with :success
       should_assign_to :company
       should_assign_to :employees
       should_render_template :index
       should_not_set_the_flash
       should "show company's employees" do
         assert_equal assigns(:employees).size, 1
         assert_equal assigns(:employees), @company.employees.by_status(Employee::Status::REJECTED).paginate(:page => 1)
       end
    end
    context "on GET to :new" do
      setup do
         get :new, :company_id => @company.id
      end
       should_respond_with :success
       should_assign_to :company
       should_render_template :new
       should_not_set_the_flash
    end
    context "on POST to :create" do
      setup do
         post :create, :company_id => @company.id,
              :user => {:email => "new_ben@test.com", :password => "benrocks", :password_confirmation => "benrocks", :login => "name",
                        :firstname => 'ben', :lastname => "afflec"},
              :employee => {:job_title => "test",
                            :phone => "12345678",
                            :company_email => "new_test",
                            :company_id => @company.id }
      end
      should_assign_to :user
      should_assign_to :company
      should_set_the_flash_to :notice
      should_respond_with :redirect
    end
    context "on POST to :create with wrong params" do
      setup do
         post :create, :company_id => @company.id,
              :user => {:email => "", :password => "benrocks", :password_confirmation => "benrocks", :login => "name",
                        :firstname => 'ben', :lastname => "afflec"},
              :employee => {:job_title => "test",
                            :phone => "12345678",
                            :company_email => "new_test",
                            :company_id => @company.id}
      end
      should_assign_to :user
      should_assign_to :company
      should_respond_with :success
      should_render_template :new
    end
    context "on GET to :edit" do
      setup do
         get :edit, :company_id => @company.id, :id => @employee.id
      end
       should_respond_with :success
       should_assign_to :company
       should_assign_to :employee
       should_render_template :edit
       should_not_set_the_flash
    end
    context "on PUT to :update" do
      setup do
         put :update, :company_id => @company.id, :id => @employee.id,
                      :employee => {:job_title => "new title"}
      end
      should_assign_to :employee
      should_assign_to :company
      should_set_the_flash_to :notice
      should_respond_with :redirect
    end
    context "on PUT to :update with wrong params" do
      setup do
         put :update, :company_id => @company.id, :id => @employee.id,
                      :employee => {:company_email_name => ""}
      end
      should_assign_to :employee
      should_assign_to :company
      should_respond_with :success
      should_render_template :edit
    end
    context "on GET to :edit_by_employee" do
      setup do
         get :edit_by_employee, :company_id => @company.id, :id => @employee.id
      end
       should_respond_with :success
       should_assign_to :company
       should_assign_to :employee
       should_render_template :edit_by_employee
       should_not_set_the_flash
    end
    context "on PUT to :update_by_employee" do
      setup do
         put :update_by_employee, :company_id => @company.id, :id => @employee.id,
                      :employee => {:phone => "666666666"}
      end
      should_assign_to :employee
      should_assign_to :company
    end
    context "on DELETE to :destroy" do
      setup do
        @employee = employees(:employee_003)
        @user = @employee.user
        @company = @employee.company
        delete :destroy, :company_id => @company.id, :id => @employee.id
      end
      should_assign_to :employee
      should_assign_to :company
      should_set_the_flash_to :notice
      should_respond_with :redirect
      should "remove only Employee relation" do
        assert_nil Employee.find_by_id assigns(:employee)
        assert_not_nil User.find_by_id assigns(:employee).user_id
      end
    end
    context "on DELETE to :destroy with error" do
      setup do
        @user = @employee.user
        Employee.any_instance.stubs(:destroy).returns(false)
        delete :destroy, :company_id => @company.id, :id => @employee.id
      end
      should_assign_to :employee
      should_assign_to :company
      should_set_the_flash_to :error
      should_respond_with :redirect
    end
    context "on POST to :destroy_all" do
      setup do
        @employees_ids = [employees(:employee_001).id, employees(:employee_002).id]
        post :destroy_all, :company_id => @company.id, :employees => @employees_ids
      end
      should_assign_to :company
      should_set_the_flash_to :notice
      should_respond_with :redirect
    end
    context "on POST to :destroy_all with destroy error" do
      setup do
        @employees_ids = [employees(:employee_001).id, employees(:employee_002).id]
        Employee.stubs(:destroy_employees).returns(employees(:employee_001))
        post :destroy_all, :company_id => @company.id, :employees => @employees_ids
      end
      should_assign_to :company
      should_set_the_flash_to :error
      should_respond_with :redirect
    end
    context "on GET to :new_recruit" do
      setup do
         get :new_recruit, :user_id => users(:user_4).id
      end
       should_respond_with :success
       should_assign_to :user
       should_render_template :new_recruit
       should_not_set_the_flash
    end
    context "on GET to :new_recruit only admin some company" do
      setup do
        login_as users(:user_4)
        get :new_recruit, :user_id => users(:frai).id
      end
      should_respond_with :redirect
      should_set_the_flash_to :error
    end
    context "on POST to :recruit" do
      setup do
         post :recruit, :company_id => @company.id, :user_id => users(:user_4).id,
              :employee => {:job_title => "test",
                            :phone => "12345678",
                            :company_email => "new_test"}
      end
      should_assign_to :user
      should_assign_to :company
      should_assign_to :employee
      should_set_the_flash_to :notice
      should_respond_with :redirect
    end
    context "on POST to :recruit with wrong params" do
      setup do
         post :recruit, :company_id => @company.id, :user_id => users(:user_4).id,
              :employee => {:company_email => nil}
      end
      should_assign_to :user
      should_assign_to :company
      should_assign_to :employee
      should_respond_with :success
      should_render_template :new
    end
    context "on GET to :devices" do
      setup do
         get :devices, :company_id => @company.id, :id => @employee.id
      end
       should_respond_with :success
       should_assign_to :employee
       should_render_template :devices
       should_not_set_the_flash
    end
    context "on PUT to :update_devices" do
      setup do
         put :update_devices, :company_id => @company.id, :id => @employee.id,
                      :employee => {:device_ids => ["1"]}
      end
      should_assign_to :employee
      should_set_the_flash_to :notice
      should_respond_with :redirect
    end
  end

  context "Invitation action" do
    context "user without password" do
      setup do
        @employee = employees(:employee_001)
        get :invitation, :invitation_token => @employee.invitation_token
      end
      should_assign_to :employee
      should_assign_to :user
      should_respond_with :redirect
    end
    context "user with password" do
      setup do
        @employee = employees(:employee_006)
        get :invitation, :invitation_token => @employee.invitation_token
      end
      should_assign_to :employee
      should_assign_to :user
      should_respond_with :redirect
    end
  end
end
