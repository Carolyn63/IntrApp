module Tools
  class NormalCrypt
    attr_reader :encrypted, :decrypted
    def initialize
      @encrypted = nil
      @decrypted = nil
    end

    def encrypt(str)
      @encrypted = ''
      i=7
      str = str.reverse
      str.each_byte do |b|
        @encrypted << (~b+i).to_s + "*"
        i = (i*i) % 423 
      end      
      @encrypted = @encrypted.chop
      
    end

    def decrypt(str)
      @decrypted = ''
      i = 7
      str.each_byte do |b|
        @decrypted << '%c' % ~(b-i)
        i = (i*i) % 423
      end
      @decrypted = @decrypted.reverse
      @decrypted
    end
  end
end
