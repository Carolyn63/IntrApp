require File.dirname(__FILE__) + '/../test_helper'
require 'dashboard_controller'

# Re-raise errors caught by the controller.
class DashboardController; def rescue_action(e) raise e end; end

class DashboardControllerTest < ActionController::TestCase

  def setup
    @controller = DashboardController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "/users/1/dashboard",        :controller => "dashboard", :action => :index, :user_id => 1

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
    end
    context "on GET to :index" do
      setup do
         get :index, :user_id => @user.id
      end
       should_assign_to :user
       should_assign_to :companies
       should_assign_to :employers_request
       should_assign_to :friends_request
       should_assign_to :employees_accepted_request
       should_assign_to :friends_accepted_request
       should_assign_to :recently_companies
       should_assign_to :recently_user
       should_respond_with :success
       should_render_template :index
       should_not_set_the_flash
       should "show user's companies" do
         assert_equal assigns(:companies), @user.employers.active_employers.paginate(:page => 1)
         assert_equal assigns(:employers_request), [companies(:company_002)]
         assert_equal assigns(:friends_request), [friendships(:new_bens_friend_with_ben)]
         assert_equal assigns(:employees_accepted_request), [employees(:employee_002)]
         assert_equal assigns(:friends_accepted_request), [friendships(:frai_with_ben)]
         assert_equal assigns(:recently_companies), Company.by_public_and_employers(@user).all(:order => "created_at DESC", :limit => 3)
         assert_equal assigns(:recently_user), User.public_and_coworkers(@user).all(:order => "created_at DESC", :limit => 3)
       end
    end
#    context "on GET to :index search" do
#      setup do
#         get :index, :user_id => @user.id, :search => companies(:company_001).name
#      end
#       should_respond_with :success
#       should_assign_to :user
#       should_assign_to :companies
#       should_render_template :index
#       should_not_set_the_flash
#       should "show user's companies" do
#         assert_equal assigns(:companies)[0], companies(:company_001)
#       end
#    end
  end

end
