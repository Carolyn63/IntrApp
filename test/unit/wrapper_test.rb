require File.dirname(__FILE__) + '/../test_helper'

class WrapperTest < ActiveSupport::TestCase
  context "An Instant" do
    setup do
      @wrapper = Services::Sogo::Wrapper.new
    end
    context "create user" do
      should "success create user" do
        RestClient::Resource.any_instance.stubs(:post).returns("success")
        assert_equal @wrapper.create_user(:email => "test@test.com", :password => "1234567"), "success"
      end
      should "failed create user" do
        begin
          RestClient::Resource.any_instance.stubs(:post).raises(RestClient::BadRequest)
          @wrapper.create_user(:email => "bad email", :password => "1234567")
        rescue => e
          assert e.kind_of?(Services::Sogo::Errors::SaveUserError)
        end
      end
    end
    context "update user" do
      should "success update user" do
        RestClient::Resource.any_instance.stubs(:post).returns("success")
        assert_equal @wrapper.update_user(:email => "new@test.com", :password => "1234567"), "success"
      end
      should "failed create user" do
        begin
          RestClient::Resource.any_instance.stubs(:post).raises(RestClient::BadRequest)
          @wrapper.update_user(:email => "bad email", :password => "1234567")
        rescue => e
          assert e.kind_of?(Services::Sogo::Errors::SaveUserError)
        end
      end
    end
    context "show user" do
      should "success get user" do
        RestClient::Resource.any_instance.stubs(:get).returns("<user><email>test@test.com</email></user>")
        assert_equal @wrapper.show_user(:email => "test@test.com"), "<user><email>test@test.com</email></user>"
      end
      should "failed show user" do
        begin
          RestClient::Resource.any_instance.stubs(:post).raises(RestClient::Unauthorized)
          @wrapper.create_user(:email => "bad email")
        rescue => e
          assert e.kind_of?(Services::Sogo::Errors::NotFound)
        end
      end
    end
    context "delete user" do
      should "success delete user" do
        RestClient::Resource.any_instance.stubs(:delete).returns("success")
        assert_equal @wrapper.delete_user(:email => "test@test.com"), "success"
      end
      should "failed delete user" do
        begin
          RestClient::Resource.any_instance.stubs(:delete).raises(RestClient::Unauthorized)
          @wrapper.delete_user(:email => "bad email")
        rescue => e
          assert e.kind_of?(Services::Sogo::Errors::NotFound)
        end
      end
    end
  end

end
