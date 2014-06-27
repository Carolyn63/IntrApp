class User3p < ActiveRecord::Base

  validates_format_of   :profile_url, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*((\.|\:)([a-z]{2,5}|[0-9]+))(([0-9]{1,5})?\/.*)?$)/

  attr_accessible :member_id, :user_id, :network, :profile_url

end
