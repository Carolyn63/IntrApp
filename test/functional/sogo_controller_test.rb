require File.dirname(__FILE__) + '/../test_helper'
require 'sogo_controller'

# Re-raise errors caught by the controller.
class SogoController; def rescue_action(e) raise e end; end

class SogoControllerTest < ActionController::TestCase

  def setup
    @controller = SogoController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "users/1/sogo/login",           :action => :login, :controller => :sogo, :user_id => "1"

  context "Not logged in" do
    context "On get to :index" do
      setup{ get :index }
      should_respond_with :redirect
    end
  end

  context "Logged in" do
    context "use sogo api" do
      setup do
        login_as users(:ben)
        @user = users(:ben)
        @company = @user.companies.first
        set_property(:use_sogo, true)
      end
      teardown do
        set_property(:use_sogo, false)
      end
      context "on GET to :login" do
        setup do
          get :login, :user_id => @user.id, :company_id => @company.id
        end
        should_assign_to :user
        should_assign_to :company
        should_assign_to :employee
        should_not_set_the_flash
        should_respond_with :redirect
      end
    end
    context "not use ondeego api" do
      setup do
        login_as users(:ben)
        @user = users(:ben)
        @company = @user.companies.first
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

