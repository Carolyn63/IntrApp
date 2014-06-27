require File.dirname(__FILE__) + '/../test_helper'

class UserSessionsControllerTest < ActionController::TestCase

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user session" do
    u = users(:ben)
    post :create, :user_session => { :login => "bjohnson@test.com", :password => "benrocks" }
    assert user_session = UserSession.find
    assert_equal users(:ben), user_session.user
    assert_redirected_to root_path
  end

  test "should destroy user session" do
    u = users(:ben)
    login_as(u)
    delete :destroy
#    assert_nil UserSession.find
    assert_redirected_to root_path
  end
end
