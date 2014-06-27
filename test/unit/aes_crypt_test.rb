require File.dirname(__FILE__) + '/../test_helper'

class AESCryptTest < ActiveSupport::TestCase

  context "An Instance" do
    setup do
      @password = "supernatural"
      @crypt = Tools::AESCrypt.new
      @encrypted = @crypt.encrypt(@password)
    end
    should "return encrypted password" do
      assert_not_nil @encrypted
      assert_equal @encrypted, @crypt.encrypted
    end
    should "return decrypt password from encrypt password and salt" do
      @new_crypt = Tools::AESCrypt.new
      @decrypted = @new_crypt.decrypt(@encrypted)
      assert_not_nil @decrypted
      assert_equal @decrypted, @password
    end
  end
end
