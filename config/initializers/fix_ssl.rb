#require 'open-uri'
#require 'net/https'

#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

#module Net
#  class HTTP
#    alias_method :original_use_ssl=, :use_ssl=
#
#    def use_ssl=(flag)
#      self.ca_file = Rails.root.join('lib/ca-bundle.crt')
#      #self.ca_path = "/usr/lib/ssl/certs"
#      self.verify_mode = OpenSSL::SSL::VERIFY_PEER
#      self.original_use_ssl = flag
#    end
#  end
#end