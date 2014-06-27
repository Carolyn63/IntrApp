require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/users_controller'

# Re-raise errors caught by the controller.
class Admin::UsersController; def rescue_action(e) raise e end; end


class Admin::UsersControllerTest < ActionController::TestCase
  
  def setup
    @controller = Admin::UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "/admin/users",           :action => :index
  should_route :get,  "/admin/users/1",         :action => :show, :id => 1
  should_route :get,  "/admin/users/new",       :action => :new
  should_route :post, "/admin/users",           :action => :create
  should_route :get,  "/admin/users/1/edit",    :action => :edit, :id => 1
  should_route :get,  "/admin/users/1/info",    :action => :info, :id => 1

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
    end
    context "on GET to :index" do
      setup do
         get :index
      end
       should_respond_with :success
       should_assign_to :users
       should_render_template :index
       should_not_set_the_flash
    end
    context "on GET to :index with filters and search" do
      setup do
        User.stubs(:search).returns(User.by_company_id(@company.id).paginate(:page => 1))
        get :index, :company_id => @company.id, :status => @user.status, :privacy => @user.privacy,
                     :mobile_tribe_user_state => @user.mobile_tribe_user_state, :search => "test"
      end
      should_respond_with :success
      should_assign_to :users
      should_render_template :index
      should_not_set_the_flash
    end
    context "on PUT to :block" do
      setup do
        put :block, :id => users(:frai).id
      end
       should_respond_with :redirect
       should_assign_to :user
       should_set_the_flash_to :notice
       should "block user" do
         assert assigns(:user).blocked?
       end
    end
    context "on PUT to :unblock" do
      setup do
        assert users(:frai).update_attributes(:status => User::Status::BLOCKED)
        put :unblock, :id => users(:frai).id
      end
       should_respond_with :redirect
       should_assign_to :user
       should_set_the_flash_to :notice
       should "unblock user" do
         assert assigns(:user).status_active?
       end
    end
    context "on GET to :info" do
      setup do
        get :info, :id => users(:ben).id
      end
      should_respond_with :success
      should_render_template :info
      should_assign_to :user
      should_assign_to :companies
      should_assign_to :friendships
      should_assign_to :contacts
      should_not_set_the_flash
      should "return right collections" do
        assert_equal assigns(:companies), [companies(:company_001), companies(:company_002), companies(:company_003)]
        assert_equal assigns(:friendships), [friendships(:ben_with_frai), friendships(:ben_with_new_bens_friend)]
        assert_equal assigns(:contacts), [employees(:employee_002), employees(:employee_005), employees(:destroy_user_as_employee)]
      end
    end
  end
  

end
