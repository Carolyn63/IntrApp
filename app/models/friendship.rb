class Friendship < ActiveRecord::Base

  module Status
    PENDING = "pending"
    ACTIVE = "active"
    REJECTED = "rejected"

    ALL = [PENDING, ACTIVE, REJECTED]

    LIST = [
      [I18n.t('models.frienship.active_employees'), ACTIVE],
      [I18n.t('models.frienship.pending_employees'), PENDING],
      [I18n.t('models.frienship.rejected_employees'), REJECTED]
    ]

    TO_LIST = {
      PENDING => I18n.t('models.frienship.pending_employees'),
      ACTIVE => I18n.t('models.frienship.active_employees'),
      REJECTED => I18n.t('models.frienship.rejected_employees')
    }
  end

  module Notification
    NEW = "new"
    DELETED = "deleted"
    DELETED_INVITATION = "deleted_invitation"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
  end

  validates_presence_of :status, :user_id, :friend_id
  validates_uniqueness_of :user_id, :scope => [:friend_id]

  belongs_to :user
  belongs_to :friend, :class_name => "User", :foreign_key => :friend_id
  belongs_to :main_friendship, :class_name => "Friendship", :foreign_key => :friendship_id
  has_one    :relate_friendship, :class_name => "Friendship", :foreign_key => :friendship_id
  
  after_create :create_friendship_with_service, :if => :multi_tenant
  before_destroy :delete_friendship_with_service, :if => :multi_tenant
  before_destroy :delete_friendship_notifier, :delete_friend_relationship
  #before_update :update_friendship_with_service, :if => :multi_tenant


  # AASM
  include AASM
  aasm_column :status
  aasm_initial_state :pending
  aasm_state :pending
  aasm_state :active
  aasm_state :rejected

  aasm_event :activate do
    transitions :to => :active, :from => [:pending, :rejected]
  end

  aasm_event :resend do
    transitions :to => :pending, :from => [:rejected]
  end

  aasm_event :reject do
    transitions :to => :rejected, :from => [:pending, :active]
  end
   aasm_event :pending do
    transitions :to => :pending, :from => [:rejected, :active]
  end

  by_whatever

  named_scope :pending, :conditions => {:status => Friendship::Status::PENDING}
  named_scope :active, :conditions => {:status => Friendship::Status::ACTIVE}
  named_scope :rejected, :conditions => {:status => Friendship::Status::REJECTED}
  named_scope :without_rejected, :conditions => ["status != ?", Friendship::Status::REJECTED]
  
  named_scope :published, lambda{
      {:conditions => ["status = ? and (published_at IS NULL or published_at >= ?)",
                        Friendship::Status::ACTIVE, Time.now.utc - 7.days]}}

  @@can_send_notification = ''
  @@mtupdated = ''
   
  def multi_tenant
   if property(:is_multi_tenant)
    return true
   else
    return false
   end
  end


  def self.accept_friendships user, ids
    unless ids.blank?
      friendships = user.incoming_requests.all(:conditions => ["id IN(?)", ids])
      friendships.each do |friendship|
        friendship.accept
      end
    end
  end

  def self.reject_friendships user, ids
    unless ids.blank?
      friendships = user.incoming_requests.all(:conditions => ["id IN(?)", ids])
      friendships.each do |friendship|
        friendship.reject
      end
    end
  end

  def self.resend_friendships user, ids
    unless ids.blank?
      friendships = user.outcoming_requests.all(:conditions => ["id IN(?)", ids])
      friendships.each do |friendship|
        #Use main friendship request for send right email
        friendship.friend_relationship.resend
      end
    end
  end

  def self.destroy_friendships user, ids
    unless ids.blank?
      friendships = user.outcoming_requests.all(:conditions => ["id IN(?)", ids])
      friendships.each do |friendship|
        #Use main friendship request for send right email
        friendship.friend_relationship.destroy
      end
    end
  end

  def self.create_friendship user, friend
    user_to_friend = Friendship.new(:user_id => user.id, :friend_id => friend.id, :friendship_id => 0)
    friend_to_user = Friendship.new(:user_id => friend.id, :friend_id => user.id)
    success = user_to_friend.valid? && friend_to_user.valid?
    if success
      @@can_send_notification = true
      user_to_friend.save
      @@can_send_notification = false
      if @@mtupdated
      friend_to_user.friendship_id = user_to_friend.id
      friend_to_user.save
      Friendship.notification(Notification::NEW, user, friend)
      end
    end
    #[user_to_friend, friend_to_user]
    success
  end

  def delete_friendship_notifier
    if self.active?
      Friendship.notification(Notification::DELETED, self.user, self.friend)
    else
      Friendship.notification(Notification::DELETED_INVITATION, self.user, self.friend)
    end
  end

  def delete_friend_relationship
    relationship = self.friend_relationship
    relationship.delete unless relationship.blank?
  end

  def delete_reject_friendships
    self.delete_friend_relationship
    self.delete
  end

  def friend_relationship
   #self.friendship_id.zero? ? self.relate_friendship : self.main_friendship
    Friendship.find_by_friend_id_and_user_id(self.user_id, self.friend_id)
  end

  def accept
    unless self.active?
        self.activate!
	if self.update_friendship_with_service
		   self.friend_relationship.activate!
		  Friendship.notification(Notification::ACCEPTED, self.friend, self.user)
	else
	          self.update_attributes(:status =>  self.friend_relationship.status)
	end
      
    end
  end

  def resend
    unless self.pending?
      self.resend!
      self.friend_relationship.resend!
      Friendship.notification(Notification::NEW, self.user, self.friend)
    end
  end

  def reject
    unless self.reject?
        self.reject!
	if self.update_friendship_with_service
		self.friend_relationship.reject!
		Friendship.notification(Notification::REJECTED, self.friend, self.user)
		return true
	else
	        self.update_attributes(:status =>  self.friend_relationship.status)
	end
      
    end
  end

  def pending?
    self.status == Friendship::Status::PENDING
  end

  def active?
    self.status == Friendship::Status::ACTIVE
  end

  def reject?
    self.status == Friendship::Status::REJECTED
  end

  def published!
    if self.active? && self.published_at.blank?
      self.published_at = Time.now.utc
      return self.save(false)
    else
      return false
    end
  end
  
  def mobiletribe_connect!
    self.update_attribute("is_mobiletribe_connect", 1)
  end

  
  def mobiletribe_connect?
    self.is_mobiletribe_connect == 1
  end

  def self.notification(kind, user, friend)
    if friend.is_friendship_notification?
#      Delayed::Job.enqueue(Delayed::FriendshipSender.new(:kind_of => kind,
#                                                         :user => user,
#                                                         :friend => friend))
      case kind
      when Notification::NEW
        FriendshipNotifier.deliver_new_friendship(user, friend)
      when Notification::DELETED
        FriendshipNotifier.deliver_delete_friendship(user, friend)
      when Notification::DELETED_INVITATION
        FriendshipNotifier.deliver_delete_friendship_invitation(user, friend)
      when Notification::ACCEPTED
        FriendshipNotifier.deliver_accepted_friendship(user, friend)
      when Notification::REJECTED
        FriendshipNotifier.deliver_rejected_friendship(user, friend)
      end
    end
  end

   protected    
      
	def create_friendship_with_service
		logger.info("Create Friendship >>>>>>>>>>>>>>>>>>>>>>>>.>")
		if(property(:use_mobile_tribe)) and @@can_send_notification
			begin
				mobile_tribe = Services::MobileTribe::Connector.new 
				logger.info("friend_id#{self.friend_id}")
				fields = {"userId" => htmlsafe(self.user_id.to_s),
				"friendId" => htmlsafe(self.friend_id.to_s)}
				mobile_tribe.create_friendship(fields)
				@@mtupdated = true
				self.mobiletribe_connect!
				#self.created!
			rescue Services::MobileTribe::Errors::MobileTribeError => e
				self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
				Friendship.find_by_id(self.id).delete
				@@mtupdated = false
				self.send(rollback_changes)
				#self.can_send_service = false
			end
		end
	end
  
 
  
  def delete_friendship_with_service
     logger.info("Delete Friendship >>>>>>>>>>>>>>>>>>>>>>>>.>")
     if(property(:use_mobile_tribe)) && self.mobiletribe_connect?
        begin
          mobile_tribe = Services::MobileTribe::Connector.new
          fields = {"userId" => htmlsafe(self.user_id.to_s), "friendId" => htmlsafe(self.friend_id.to_s)}
          mobile_tribe.destroy_friendship(fields)
        rescue Services::MobileTribe::Errors::MobileTribeError => e
          self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
          self.send(:rollback_changes)
          return false
        end
    end
  end
  
   def update_friendship_with_service
        logger.info("Update Friendship >>>>>>>>>>>>>>>>>>>>>>>>.>")
	success = true 
	if(property(:use_mobile_tribe)) && self.mobiletribe_connect?
		mobile_tribe = Services::MobileTribe::Connector.new
		begin
			user_id = self.friend_id.to_s
			friend_id = self.user_id.to_s
			fields = {"userId" => user_id,
				  "friendId" => friend_id
			         }
    
			if (self.status == Friendship::Status::ACTIVE)
				friendship_status = 'accept'
				logger.info("Accept.................")

			elsif(self.status == Friendship::Status::REJECTED)
				friendship_status = 'reject'
					logger.info("Reject.................")
			end  
			
			fields["friendAction"] = friendship_status
			mobile_tribe.update_friendship(fields)
			success = true
		rescue Services::MobileTribe::Errors::MobileTribeError => e
			self.errors.add_to_base( "#{I18n.t('models.company.mobile_tribe_error')} #{e.to_s}" )
			success = false
		end
	end
	return success
  end
  
     
    def rollback_changes
        raise ActiveRecord::Rollback, "Something went wrong with MTP, check the logs!"
    end
    
    
    def htmlsafe(str)
        @escaped = URI::escape(str.to_s)
        return @escaped
    end
  
end
