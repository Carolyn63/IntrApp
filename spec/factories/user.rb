Factory.define :user do |e|
  e.firstname             { 'John' }
  e.lastname              { 'Doe' }

  e.sequence(:login)      { |n| "John #{ n }" }

  e.sequence(:email)      { |n| "user#{ n }@example.com" }

  e.password              { 'password' }
  e.password_confirmation { 'password' }


  # id: 1
  # email: bjohnson@test.com
  # password_salt: <%= salt = Authlogic::Random.hex_token %>
  # crypted_password: <%= Authlogic::CryptoProviders::Sha512.encrypt("benrocks" + salt) %>
  # persistence_token: 6cde0674657a8a313ce952df979de2830309aa4c11ca65805dd00bfdc65dbcc2f5e36718660a1d2e68c1a08c276d996763985d2f06fd3d076eb7bc4d97b1e317
  # single_access_token: <%= Authlogic::Random.friendly_token %>
  # perishable_token: <%= Authlogic::Random.friendly_token %>
  # firstname: "Ben"
  # lastname: "bender"
  # login: "ben"
  # mobile_tribe_login: "test"
  # mobile_tribe_password: "test"
  # mobile_tribe_user_state: 1
  # address: "New Your"
  # phone: "123-133-1234"
  # cellphone: "123-133-1234"
  # age: "40"
  # sex: "40"
  # site: "http://google.com"
  # description: "blablablba"
  # role: <%= User::Role::ADMIN %>
  # job_title: "Manager"
  # user_password: <%= Tools::AESCrypt.new.encrypt("benrock") %>

end
