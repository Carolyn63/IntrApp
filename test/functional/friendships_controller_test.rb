require File.dirname(__FILE__) + '/../test_helper'
require 'friendships_controller'

# Re-raise errors caught by the controller.
class FriendshipsController; def rescue_action(e) raise e end; end

class FriendshipsControllerTest < ActionController::TestCase

  def setup
    @controller = FriendshipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

  end

  should_route :get,  "/users/1/friendships",          :action => :index, :user_id => 1
  should_route :get,  "/users/1/friendships/1",        :action => :show, :user_id => 1, :id => 1
  should_route :get,  "/users/1/friendships/new",      :action => :new, :user_id => 1
  should_route :post, "/users/1/friendships",          :action => :create, :user_id => 1
  should_route :get,  "/users/1/friendships/1/edit",   :action => :edit, :user_id => 1, :id => 1
  should_route :post,  "/users/1/friendships/accept_all",                  :action => :accept_all, :user_id => 1
  should_route :post,  "/users/1/friendships/reject_all",                  :action => :reject_all, :user_id => 1
  should_route :post,  "/users/1/friendships/resend_all",                  :action => :resend_all, :user_id => 1
  should_route :post,  "/users/1/friendships/destroy_all",                 :action => :destroy_all, :user_id => 1
  should_route :get,  "/users/1/friendships/incoming_requests",           :action => :incoming_requests, :user_id => 1
  should_route :get,  "/users/1/friendships/outcoming_requests",          :action => :outcoming_requests, :user_id => 1
  should_route :get,  "/users/1/friendships/rejected_outcoming_requests", :action => :rejected_outcoming_requests, :user_id => 1

  context "Not logged in" do
    context "On get to :index" do
      setup{ get :index }
      should_respond_with :redirect
    end
  end

  context "Logged in" do
    setup do
      @user = users(:ben)
      login_as @user
      @request.env["HTTP_REFERER"] = 'http://test.host/last/page/visited'
    end
    context "on POST to :accept_all " do
      setup do
        @friendship = friendships(:new_bens_friend_with_ben)
        post :accept_all, :user_id =>  @user.id, :friendships => [@friendship.id]
        @friendship.reload
      end
      should_respond_with :redirect
      should_assign_to :user
      should "accept friendships" do
        assert_equal @friendship.status, Friendship::Status::ACTIVE
      end
    end
    context "on GET to :accept " do
      setup do
        @friendship = friendships(:new_bens_friend_with_ben)
        get :accept, :user_id =>  @user.id, :id => @friendship.id
        @friendship.reload
      end
      should_respond_with :redirect
      should_assign_to :user
      should_assign_to :friendship
      should "accept friendship" do
        assert_equal @friendship.status, Friendship::Status::ACTIVE
      end
    end
    context "on GET to :accept only for current user incoming friendship request" do
      setup do
        @friendship = friendships(:frai_with_user_3)
        get :accept, :user_id =>  @user.id, :id => @friendship.id
        @friendship.reload
      end
      should_respond_with :redirect
      should_set_the_flash_to :error
      should "accept friendship" do
        assert_equal @friendship.status, Friendship::Status::PENDING
      end
    end
    context "on GET to :reject " do
      setup do
        @friendship = friendships(:new_bens_friend_with_ben)
        get :reject, :user_id =>  @user.id, :id => @friendship.id
        @friendship.reload
      end
      should_respond_with :redirect
      should_assign_to :user
      should_assign_to :friendship
      should "accept friendship" do
        assert_equal @friendship.status, Friendship::Status::REJECTED
      end
    end
    context "on POST to :reject_all " do
      setup do
        @friendship = friendships(:new_bens_friend_with_ben)
        post :reject_all, :user_id =>  @user.id, :friendships => [@friendship.id]
        @friendship.reload
      end
      should_respond_with :redirect
      should_assign_to :user
      should "reject friendships" do
        assert_equal @friendship.status, Friendship::Status::REJECTED
      end
    end
    context "on POST to :resend_all " do
      setup do
        @user = users(:frai)
        login_as @user
        @friendship = friendships(:user_4_with_frai)
        post :resend_all, :user_id =>  @user.id, :friendships => [@friendship.id]
        @friendship.reload
      end
      should_respond_with :redirect
      should_assign_to :user
      should "resend friendships" do
        assert_equal @friendship.status, Friendship::Status::PENDING
      end
    end
    context "on POST to :destroy_all " do
      setup do
        @user = users(:frai)
        login_as @user
        @friendship = friendships(:user_4_with_frai)
        post :destroy_all, :user_id =>  @user.id, :friendships => [@friendship.id]
      end
      should_respond_with :redirect
      should_assign_to :user
      should "delete friendships" do
        assert_nil Friendship.find_by_id(@friendship.id)
      end
    end
  end
end

