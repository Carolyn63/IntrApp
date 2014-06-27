module Tools
  class BlowfishCrypt
    attr_reader :encrypted, :decrypted

    def initialize
      @encrypted = nil
      @decrypted = nil
      @key = "nK9XUuzzoGeR/Hr/eXFQ0g=="
      @options = {:algorithm=>"blowfish"}
    end
    
    def encrypt(password, salt)
      key = EzCrypto::Key.with_password(@key, salt, @options)
      @encrypted = key.encrypt64(password).strip.delete("\n")
      @encrypted
    end

    def decrypt(password, salt)
      decrypt_key = EzCrypto::Key.with_password(@key, salt, @options)
      @decrypted = decrypt_key.decrypt64(password)
      @decrypted
    end
  end
end
