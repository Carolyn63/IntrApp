require File.dirname(__FILE__) + '/../test_helper'

class FriendshipTest < ActiveSupport::TestCase
   context "the Friendship class" do
    should_validate_presence_of :user_id, :friend_id

    should_belong_to :user
    #should_has_one :friend_relationship

    should "make friends " do
      user = users(:ben)
      friend = users(:user_4)
      assert_difference 'Friendship.count', 2 do
        Friendship.create_friendship user, friend
      end
    end
    should "accept friendships" do
      friendship = friendships(:new_bens_friend_with_ben)
      assert_equal friendship.status, Friendship::Status::PENDING
      Friendship.accept_friendships(users(:ben), [friendship])
      friendship.reload
      assert_equal friendship.status, Friendship::Status::ACTIVE
      assert_equal friendship.friend_relationship.status, Friendship::Status::ACTIVE
    end
    should "accept friendships only from incoming requests" do
      friendship = friendships(:new_bens_friend_with_ben)
      assert_equal friendship.status, Friendship::Status::PENDING
      Friendship.accept_friendships(users(:new_bens_friend), [friendship])
      friendship.reload
      assert_equal friendship.status, Friendship::Status::PENDING
      assert_equal friendship.friend_relationship.status, Friendship::Status::PENDING
    end
    should "reject friendships" do
      friendship = friendships(:new_bens_friend_with_ben)
      assert_equal friendship.status, Friendship::Status::PENDING
      Friendship.reject_friendships(users(:ben), [friendship])
      friendship.reload
      assert_equal friendship.status, Friendship::Status::REJECTED
      assert_equal friendship.friend_relationship.status, Friendship::Status::REJECTED
    end
    should "reject friendships only from incoming requests" do
      friendship = friendships(:new_bens_friend_with_ben)
      assert_equal friendship.status, Friendship::Status::PENDING
      Friendship.reject_friendships(users(:new_bens_friend), [friendship])
      friendship.reload
      assert_equal friendship.status, Friendship::Status::PENDING
      assert_equal friendship.friend_relationship.status, Friendship::Status::PENDING
    end
    should "resend friendships" do
      friendship = friendships(:user_4_with_frai)
      assert_equal friendship.status, Friendship::Status::REJECTED
      Friendship.resend_friendships(users(:frai), [friendship])
      friendship.reload
      assert_equal friendship.status, Friendship::Status::PENDING
      assert_equal friendship.friend_relationship.status, Friendship::Status::PENDING
    end
    should "resend friendships only from outcoming request" do
      friendship = friendships(:user_4_with_frai)
      assert_equal friendship.status, Friendship::Status::REJECTED
      Friendship.resend_friendships(users(:user_4), [friendship])
      friendship.reload
      assert_equal friendship.status, Friendship::Status::REJECTED
      assert_equal friendship.friend_relationship.status, Friendship::Status::REJECTED
    end
    should "destoy friendships" do
      friendship = friendships(:frai_with_ben)
      assert_equal friendship.status, Friendship::Status::ACTIVE
      Friendship.destroy_friendships(users(:ben), [friendship])
      assert_nil Friendship.find_by_id(friendship.id)
    end
    should "destoy friendships only from outcoming request" do
      friendship = friendships(:frai_with_ben)
      assert_equal friendship.status, Friendship::Status::ACTIVE
      Friendship.destroy_friendships(users(:frai), [friendship])
      assert_not_nil Friendship.find_by_id(friendship.id)
    end
    should "return right active published friendship" do
      @ben_friendship = friendships(:ben_with_frai)
      @frai_friendship = friendships(:frai_with_ben)
      assert_equal Friendship.published, [@ben_friendship, @frai_friendship]
      @ben_friendship.update_attributes(:published_at => Time.now.utc - 8.days)
      assert_equal Friendship.published, [@frai_friendship]
    end
    should "return only active published friendship" do
      @ben_friendship = friendships(:ben_with_frai)
      @frai_friendship = friendships(:frai_with_ben)
      @ben_friendship.update_attributes(:status => Friendship::Status::PENDING)
      assert_equal Friendship.published, [@frai_friendship]
    end
  end

  context "An Instance" do
    setup do
      @friendship = friendships(:ben_with_frai)
      @friendship.update_attributes(:status => Friendship::Status::PENDING)
    end
    should "from pending to active" do
      assert_equal @friendship.status, Friendship::Status::PENDING
      @friendship.activate!
      assert_equal @friendship.status, Friendship::Status::ACTIVE
    end
    should "from pending to rejected" do
      assert_equal @friendship.status, Friendship::Status::PENDING
      @friendship.reject!
      assert_equal @friendship.status, Friendship::Status::REJECTED
    end
    should "from active to rejected" do
      @friendship.update_attributes(:status => Friendship::Status::ACTIVE)
      assert_equal @friendship.status, Friendship::Status::ACTIVE
      @friendship.reject!
      assert_equal @friendship.status, Friendship::Status::REJECTED
    end
    should "from rejected to active" do
      @friendship.update_attributes(:status => Friendship::Status::REJECTED)
      assert_equal @friendship.status, Friendship::Status::REJECTED
      @friendship.activate!
      assert_equal @friendship.status, Friendship::Status::ACTIVE
    end
    should "from rejected to pending" do
      @friendship.update_attributes(:status => Friendship::Status::REJECTED)
      assert_equal @friendship.status, Friendship::Status::REJECTED
      @friendship.resend!
      assert_equal @friendship.status, Friendship::Status::PENDING
    end
    should "has friend_relationship" do
      assert_not_nil @friendship.friend_relationship
      assert_equal @friendship.friend_relationship.user_id, @friendship.friend_id
      assert_equal @friendship.friend_relationship.friend_id, @friendship.user_id
    end
    should "has main_friendship" do
      @friendship = friendships(:frai_with_ben)
      assert_not_nil @friendship.main_friendship
      assert_nil @friendship.relate_friendship
      assert_equal @friendship.main_friendship, friendships(:ben_with_frai)
    end
    should "has relate_friendship" do
      assert_nil @friendship.main_friendship
      assert_not_nil @friendship.relate_friendship
      assert_equal @friendship.relate_friendship, friendships(:frai_with_ben)
    end
    should "remove all association" do
      friend_relationship = @friendship.friend_relationship
      assert @friendship.destroy
      assert_nil Friendship.find_by_id(@friendship.id)
      assert_nil Friendship.find_by_id(friend_relationship.id)
    end
    should "accept friendship" do
      @friendship = friendships(:ben_with_new_bens_friend)
      assert_equal @friendship.status, Friendship::Status::PENDING
      assert_equal @friendship.friend_relationship.status, Friendship::Status::PENDING
      @friendship.accept
      assert_equal @friendship.status, Friendship::Status::ACTIVE
      assert_equal @friendship.friend_relationship.status, Friendship::Status::ACTIVE
    end
    should "rejected friendship" do
      @friendship = friendships(:ben_with_new_bens_friend)
      assert_equal @friendship.status, Friendship::Status::PENDING
      assert_equal @friendship.friend_relationship.status, Friendship::Status::PENDING
      @friendship.reject
      assert_equal @friendship.status, Friendship::Status::REJECTED
      assert_equal @friendship.friend_relationship.status, Friendship::Status::REJECTED
    end
    should "rejected friendship" do
      @friendship = friendships(:frai_with_user_4)
      assert_equal @friendship.status, Friendship::Status::REJECTED
      assert_equal @friendship.friend_relationship.status, Friendship::Status::REJECTED
      @friendship.resend
      assert_equal @friendship.status, Friendship::Status::PENDING
      assert_equal @friendship.friend_relationship.status, Friendship::Status::PENDING
    end
    should "published only active friendship" do
      @friendship.update_attributes(:status => Friendship::Status::ACTIVE)
      @friendship = friendships(:ben_with_frai)
      assert @friendship.update_attributes(:published_at => nil)
      assert @friendship.published!
      assert !@friendship.published_at.blank?
    end
    should "not published already published friendship" do
      @friendship.update_attributes(:status => Friendship::Status::ACTIVE)
      @friendship = friendships(:ben_with_frai)
      published_at = @friendship.published_at
      assert !@friendship.published!
      assert_equal @friendship.published_at, published_at
    end
    should "not published not active published friendship" do
      assert @friendship.update_attributes(:published_at => nil)
      assert @friendship.published_at.blank?
      assert !@friendship.published!
      assert @friendship.published_at.blank?
    end
  end

  context "On create" do
    should "with right " do
      assert_difference 'Friendship.count' do
        friendship = create_friendship
        assert_valid friendship
        assert !friendship.new_record?, "#{friendship.errors.full_messages.to_sentence}"
      end
    end
    should "without name" do
      assert_no_difference('Friendship.count') do
        friendship = create_friendship(:friend_id => users(:frai).id)
        assert friendship.errors.on(:user_id)
      end
    end
  end

  protected

  def create_friendship options = {}
    Friendship.create({
        :user_id => users(:ben).id,
        :friend_id => users(:user_3).id,
        :status => Friendship::Status::PENDING
      }.merge(options))
  end

end
