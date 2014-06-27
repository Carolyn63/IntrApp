require File.dirname(__FILE__) + '/../test_helper'
require 'support_controller'

# Re-raise errors caught by the controller.
class SupportController; def rescue_action(e) raise e end; end

class SupportControllerTest < ActionController::TestCase

  def setup
    @controller = SupportController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

  end

  should_route :get,  "/support/contact_us",            :controller => :support, :action => :contact_us
  should_route :get,  "/support/send_contact_us_email", :controller => :support, :action => :send_contact_us_email

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
    context "on GET to :contact_us" do
      setup do
         get :contact_us
      end
      should_respond_with :success
      should_render_template :contact_us
      should_not_set_the_flash
    end
    context "on POST to :send_contact_us_email" do
      setup do
         post :send_contact_us_email, :email => "test@test.com", :name => "test", :reason => "test",
                                      :description => "test"
      end
      should_respond_with :redirect
      should_set_the_flash_to :notice
    end
  end

end
