require File.dirname(__FILE__) + '/../test_helper'

class OauthHelperTest < ActiveSupport::TestCase
  context "An Class" do
    should "return right oauth parameters without token" do
      parameters = Services::OnDeego::OauthHelper.oauth_parameters
      par = {"oauth_signature_method"=>"HMAC-SHA1", "oauth_consumer_key"=>property(:ondeego_consumer_key).to_s,"oauth_version"=>"1.0"}
      assert_equal par, parameters.reject{|k,v| ["oauth_nonce", "oauth_timestamp", "oauth_signature"].include?(k) }
    end
    should "return right oauth parameters token" do
      parameters = Services::OnDeego::OauthHelper.oauth_parameters(:oauth_token => "token", :oauth_secret => "secret")
      par = {"oauth_signature_method"=>"HMAC-SHA1", "oauth_consumer_key"=>property(:ondeego_consumer_key).to_s,"oauth_version"=>"1.0", "oauth_token" => "token"}
      assert_equal par, parameters.reject{|k,v| ["oauth_nonce", "oauth_timestamp", "oauth_signature"].include?(k) }
    end
  end

end
