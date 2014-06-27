require 'user'

module Delayed 
  class FriendshipSender < Struct.new(:params)
    def perform
      case params[:kind_of]
      when Friendship::Notification::NEW
         FriendshipNotifier.deliver_new_friendship(params[:user], params[:friend])
      when Friendship::Notification::DELETED
         FriendshipNotifier.deliver_delete_friendship(params[:user], params[:friend])
      when Friendship::Notification::ACCEPTED
         FriendshipNotifier.deliver_accepted_friendship(params[:user], params[:friend])
      when Friendship::Notification::REJECTED
         FriendshipNotifier.deliver_rejected_friendship(params[:user], params[:friend])
      end
    end
  end
end
