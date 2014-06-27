require File.dirname(__FILE__) + '/../test_helper'
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < ActionController::TestCase

  def setup
    @controller = SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "/search/users",     :action => :users, :controller => :search
  should_route :get,  "/search/companies", :action => :companies, :controller => :search

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
      User.stubs(:search).returns(User.paginate(:page => 1))
      Company.stubs(:search).returns(Company.paginate(:page => 1))
      Company.stubs(:sphinx_public_and_employers).returns(Company)
      User.stubs(:sphinx_public_and_coworkers).returns(User)
    end
    context "on GET to :users" do
      setup do
         get :users
      end
       should_respond_with :success
       should_assign_to :users
       should_render_template :users
       should_not_set_the_flash
       should "show users" do
         assert_equal assigns(:users), User.paginate(:page => 1)
       end
    end
    context "on GET to :users" do
      setup do
         get :users, :search => @user.email
      end
       should_respond_with :success
       should_assign_to :users
       should_assign_to :companies
       should_render_template :users
       should_not_set_the_flash
       should "show users" do
         assert_equal assigns(:users), User.paginate(:page => 1)
       end
    end
    context "on GET to :users" do
      setup do
         get :users, :search => @user.email
      end
       should_respond_with :success
       should_assign_to :users
       should_assign_to :companies
       should_render_template :users
       should_not_set_the_flash
       should "show users" do
         assert_equal assigns(:users), User.paginate(:page => 1)
       end
    end
    context "on GET to :companies" do
      setup do
         get :companies, :search => @company.name
      end
       should_respond_with :success
       should_assign_to :companies
       should_render_template :companies
       should_not_set_the_flash
       should "show users" do
         assert_equal assigns(:companies), Company.paginate(:page => 1)
       end
    end
  end
end
