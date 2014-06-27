# TRAC - Models - Frienship_Notifier - FriendshipNotifier
#
# Adds more values for sending email when someone requests, sends
# or accepts a friendship invite.

class FriendshipNotifier < ActionMailer::Base

  def new_friendship(user, friend)
    setup
    subject    "oToGo Mobile : #{user.name} has sent you a friendship request"
    recipients friend.email
    body       :user => user,
               :profile_url => user_url(user),
               :accept_url => accept_user_friendship_url(friend.id, Friendship.find_by_friend_id_and_user_id(friend.id, user.id).id),
               :site_url => property(:domain),
               :root_url => root_url,
               :to_user_profile_url => user_url(friend),
               :to_user => friend.name,
               :sent_on_time => sent_on.strftime("%H:%M"),
               :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def delete_friendship(user, friend)
    setup
    subject    "oToGo Mobile : #{user.name} has removed you from their friend list."
    recipients friend.email
    body       :user => user,
               :profile_url => user_url(user),
               :site_url => property(:domain),
               :root_url => root_url,
               :to_user_profile_url => user_url(friend),
               :to_user => friend.name,
               :sent_on_time => sent_on.strftime("%H:%M"),
               :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def delete_friendship_invitation(user, friend)
    setup
    subject    "oToGo Mobile : #{user.name} has deleted the friend request they sent you earlier."
    recipients friend.email
    body       :user => user,
               :profile_url => user_url(user),
               :site_url => property(:domain),
               :root_url => root_url,
               :to_user_profile_url => user_url(friend),
               :to_user => friend.name,
               :sent_on_time => sent_on.strftime("%H:%M"),
               :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def accepted_friendship(user, friend)
    setup
    subject    "oToGo Mobile : #{user.name} has confirmed you as a friend"
    recipients friend.email
    body       :user => user,
               :profile_url => user_url(user),
               :site_url => property(:domain),
               :root_url => root_url,
               :to_user_profile_url => user_url(friend),
               :to_user => friend.name,
               :sent_on_time => sent_on.strftime("%H:%M"),
               :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  def rejected_friendship(user, friend)
    setup
    subject    "oToGo Mobile : #{user.name} has declined your friendship request"
    recipients friend.email
    body       :user => user,
               :profile_url => user_url(user),
               :site_url => property(:domain),
               :root_url => root_url,
               :to_user_profile_url => user_url(friend),
               :to_user => friend.name,
               :sent_on_time => sent_on.strftime("%H:%M"),
               :sent_on_date => sent_on.strftime("%A %d %B %Y")
  end

  protected

  def setup
    content_type "text/html"
    from          property(:email_from)
    sent_on       Time.now
  end

end
