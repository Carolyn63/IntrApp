require File.dirname(__FILE__) + '/../../../test_helper'
require 'api/v2/companies_controller'

# Re-raise errors caught by the controller.
class Api::V2::CompaniesController; def rescue_action(e) raise e end; end

class Api::V2::CompaniesControllerTest < ActionController::TestCase

  def setup
    @controller = Api::V2::CompaniesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "/api/v2/companies",               :action => :index
  should_route :get,  "/api/v2/companies/create_success", :action => :create_success
  should_route :get,  "/api/v2/companies/create_fail",    :action => :create_fail

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
    context "on GET to :create_success" do
      setup do
        Services::OnDeego::OauthClient.any_instance.stubs(:get_access_token).returns(OAuth::Token.new("token", "secret"))
        get :create_success, :company_key => @company.perishable_token, :employee_key => @employee.perishable_token,
                             :userId => 1, :companyId => 1
      end
      should_assign_to :employee
      should_assign_to :company
      should_respond_with :redirect
      should_set_the_flash_to :notice
      should "update company and employee" do
        assert_equal assigns(:company).ondeego_company_id, 1
        assert_equal assigns(:company).is_ondeego_connect, 1
        assert_equal assigns(:employee).ondeego_user_id, 1
        assert_equal assigns(:employee).is_ondeego_connect, 1
        assert_equal assigns(:employee).oauth_token, "token"
        assert_equal assigns(:employee).oauth_secret, "secret"
      end
    end
    context "on GET to :create_success with not own company" do
      setup do
        get :create_success, :company_key => "1", :employee_key => @employee.perishable_token,
                             :userId => 1, :companyId => 1
      end
      should_respond_with :redirect
      should_set_the_flash_to :error
    end
    context "on GET to :create_fail" do
      setup do
        get :create_fail, :company_key => @company.perishable_token, :employee_key => @employee.perishable_token
      end
      should_assign_to :employee
      should_assign_to :company
      should_respond_with :redirect
      should_set_the_flash_to :error
    end
  end

end
