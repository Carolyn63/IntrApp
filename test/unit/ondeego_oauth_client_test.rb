require File.dirname(__FILE__) + '/../test_helper'

class OnDeegoOauthClientTest < ActiveSupport::TestCase
  context "An Instant" do
    setup do
      @client = Services::OnDeego::OauthClient.new
      @action = Services::OnDeego::OauthClient::ACTIONS::API_BASE
    end
    context "request_by_post method" do
      context "process Exceptions" do
        context "OAuth" do
          [RestClient::InternalServerError, RestClient::Unauthorized, RestClient::BadGateway,
            RestClient::BadRequest, RestClient::Forbidden, RestClient::ResourceNotFound].each do |exception|
            should "return right message for #{exception}" do
              begin
                RestClient.stubs(:post).raises(exception)
                @client.send(:request_by_post, @action)
              rescue => e
                assert e.kind_of?(Services::OnDeego::Errors::OAuthError)
                assert_equal e.to_s, Services::OnDeego::Errors::Messages::TO_MESSAGE[exception]
              end
            end
          end
        end
        context "other Exceptions" do
          should "rescue and return message" do
            begin
              RestClient.stubs(:post).raises(Exception)
              @client.send(:request_by_post, @action)
            rescue => e
              assert e.kind_of?(Services::OnDeego::Errors::GenerickError)
              assert_not_nil e.to_s
            end
          end
        end
      end
      context "success response" do
        should "return 200 code" do
          response = RestClient.stubs(:post).returns("<html>response</html>")
          assert_not_nil response
        end
      end
    end
    context "delete_company method" do
      setup do
        @client = Services::OnDeego::OauthClient.new(:oauth_token => "key", :oauth_secret => "secret")
      end
      should "return success response" do
        response = RestClient.stubs(:post).returns("<html>success</html>")
        assert_equal @client.delete_company("companyId" => "1"), "<html>success</html>"
        assert_equal({"oauth_signature_method"=>"HMAC-SHA1",
                      "oauth_token"=>"key",
                      "oauth_consumer_key"=>property(:ondeego_consumer_key).to_s,
                      "oauth_version"=>"1.0"}, @client.send(:oauth_hash).reject{|k,v| ["oauth_nonce", "oauth_timestamp", "oauth_signature"].include?(k) })
      end
    end
  end

end
