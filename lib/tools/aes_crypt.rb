module Tools
  class AESCrypt
    attr_reader :encrypted, :decrypted

    def initialize
      @encrypted = nil
      @decrypted = nil
      @key = property(:aes_key)
      @options = {}
    end
    
    def encrypt(password)
      key = EzCrypto::Key.new(@key, @options)
      @encrypted = key.encrypt64(password).strip.delete("\n")
      @encrypted
    end

    def decrypt(password)
      decrypt_key = EzCrypto::Key.new(@key, @options)
      @decrypted = decrypt_key.decrypt64(password)
      @decrypted
    end
  end
end
