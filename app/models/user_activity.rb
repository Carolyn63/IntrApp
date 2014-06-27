class UserActivity < ActiveRecord::Base
  
 def self.create_user_activity fields
   unless fields.blank?
     @activity = UserActivity.new(fields)
     return true if @activity.save
   end
 end  
  
end
