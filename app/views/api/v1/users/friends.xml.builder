xml = Builder::XmlMarkup.new
xml.instruct!
xml.friends do |friend|
  @friends.each do |friend|
    xml.friend do
      xml.tag!( :firstname, friend.firstname)
      xml.tag!( :lastname, friend.lastname)
      xml.tag!( :username, friend.login)
      xml.tag!( :email, friend.email)
    end
  end
end 