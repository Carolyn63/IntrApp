require File.dirname(__FILE__) + '/../test_helper'

class BlowfishCryptTest < ActiveSupport::TestCase

  context "An Instance" do
    setup do
      @password = "supernatural"
      @salt = Authlogic::Random.friendly_token
      @crypt = Tools::BlowfishCrypt.new
      @encrypted = @crypt.encrypt(@password, @salt)
    end
    should "return encrypted password" do
      assert_not_nil @encrypted
      assert_equal @encrypted, @crypt.encrypted
    end
    should "return decrypt password from encrypt password and salt" do
      @new_crypt = Tools::BlowfishCrypt.new
      @decrypted = @new_crypt.decrypt(@encrypted, @salt)
      assert_not_nil @decrypted
      assert_equal @decrypted, @password
    end
  end
end
