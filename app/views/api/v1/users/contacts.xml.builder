xml = Builder::XmlMarkup.new
xml.instruct!
xml.contacts do |contact|
  @contacts.each do |contact|
    xml.contact do
      xml.tag!( :company, contact.company.name)
      xml.tag!( :firstname, contact.user.firstname)
      xml.tag!( :lastname, contact.user.lastname)
      xml.tag!( :username, contact.user.login)
      xml.tag!( :email, contact.user.email)
    end
  end
end 