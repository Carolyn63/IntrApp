require File.dirname(__FILE__) + '/../../../test_helper'
require 'api/v1/users_controller'

# Re-raise errors caught by the controller.
class Api::V1::UsersController; def rescue_action(e) raise e end; end

class Api::V1::UsersControllerTest < ActionController::TestCase

  def setup
    @controller = Api::V1::UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  should_route :get,  "/api/v1/users/1/contacts",      :action => :contacts, :id => 1
  should_route :get,  "/api/v1/users/1/contacts.xml",  :action => :contacts, :id => 1, :format => "xml"
  should_route :get,  "/api/v1/users/1/friends",       :action => :friends, :id => 1
  should_route :get,  "/api/v1/users/1/friends.xml",   :action => :friends, :id => 1, :format => "xml"

  context "On basic authentication login" do
    setup do
      @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("ben:benrocks")
    end
    context "On get to :contacts" do
      setup do
        @user = users( :ben )
        get :contacts, :id => @user.login, :format => "xml"
      end
      should_respond_with :success
      should_respond_with_content_type "application/xml"
      should "return contacts" do
        assert_equal @user.contacts, assigns(:contacts)
      end
    end
    context "On get to :friends" do
      setup do
        @user = users( :ben )
        get :friends, :id => @user.login, :format => "xml"
      end
      should_respond_with :success
      should_respond_with_content_type "application/xml"
      should "return friends" do
        assert_equal @user.friends, assigns(:friends)
      end
    end
  end

end
