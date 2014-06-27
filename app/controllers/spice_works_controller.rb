gem 'oauth'
require 'oauth/consumer'

class SpiceWorksController < ApplicationController
#Consumer Key: iaKJwkvaPAAlHfxDxJBI
#Consumer Secret: 06QdYrY7cOyGIa3V3ond1wIzcmvjIPOvhRzh26Pk
#Request Token URL http://community.spiceworks.com/oauth/request_token
#Access Token URL http://community.spiceworks.com/oauth/access_token
#Authorize URL http://community.spiceworks.com/public_oauth/authorize 

def do_login
@consumer=OAuth::Consumer.new "iaKJwkvaPAAlHfxDxJBI", 
                              "06QdYrY7cOyGIa3V3ond1wIzcmvjIPOvhRzh26Pk", 
                              {:site=>"http://community.spiceworks.com"}
@request_token=@consumer.get_request_token
logger.info("Request Object type#{@request_token.class}")
logger.info("request URL... #{@request_token.authorize_url}")
end

end