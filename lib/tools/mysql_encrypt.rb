module Tools
  class MysqlEncrypt
    def self.mysql_encrypt(pw)
      salt = [Array.new(6){rand(256).chr}.join].pack("m").chomp
      return pw.to_s.crypt(salt)
    end
  end
end
