require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < ActionController::TestCase

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  context "Not logged in" do
    context "On get to :new or :signup" do
      setup{ get :new }
      should_render_template :new
      should_assign_to :user
      should_respond_with :success
    end
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should get index" do
    login_as(users(:ben))
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_not_nil assigns(:recently_users)
  end

  test "should get index search" do
    login_as(users(:ben))
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal assigns(:users)[0], users(:ben)
  end

  test "should create user" do
    assert_difference('User.count') do
      post :create, :user => { :email => "ben@test.com", :password => "benrocks", :password_confirmation => "benrocks", :login => "name",
                               :firstname => 'ben', :lastname => "afflec"}
    end

    assert_redirected_to root_path
  end

  test "should show user" do
    login_as(users(:ben))
    get :show, :id => users(:ben).id
     assert_not_nil assigns(:companies)
     assert_not_nil assigns(:employees)
     assert_not_nil assigns(:user)
    assert_response :success
  end

  test "should not show private user profile" do
    login_as(users(:ben))
    get :show, :id => users(:user_without_password).id
    assert_not_nil assigns(:user)
    assert_response :redirect
  end

  test "should show private user profile if user coworker" do
    login_as(users(:ben))
    get :show, :id => users(:frai).id
    assert_response :success
     assert_not_nil assigns(:companies)
     assert_not_nil assigns(:employees)
     assert_not_nil assigns(:user)
  end

  test "should get edit" do
    login_as(users(:ben))
    get :edit, :id => users(:ben).id
    assert_response :success
  end

  test "should update user" do
    login_as(users(:ben))
    put :update, :id => users(:ben).id, :user => {:firstname => "d"}
    assert_redirected_to root_path
  end

  test "should :get friendship_request" do
    login_as(users(:ben))
    assert_difference 'Friendship.count', 2 do
      get :friendship_request, :id => users(:ben).id, :friend_id => users(:user_3)
      assert_not_nil assigns(:user)
      assert_not_nil assigns(:friend)
      assert_redirected_to user_path(users(:user_3))
    end
  end

  test "should :get friendship_delete" do
    @request.env["HTTP_REFERER"] = 'http://test.host/users/2'
    login_as(users(:ben))
    get :friendship_delete, :id => users(:ben).id, :friend_id => users(:frai)
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:friend)
    assert_redirected_to user_path(users(:frai))
  end

  test "should :get contacts" do
    login_as(users(:ben))
    get :contacts, :id => users(:ben).id
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:contacts)
    assert_response :success
  end

  test "should :get friends" do
    login_as(users(:ben))
    get :friends, :id => users(:ben).id
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:friends)
    assert_response :success
  end

  test "should not login for blocked user" do
    u = users(:ben)
    u.change_status(User::Status::BLOCKED)
    login_as(u)
    get :index
    assert_redirected_to root_path
  end
end
