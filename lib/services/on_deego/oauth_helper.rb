module Services
  module OnDeego
    class OauthHelper

      def self.oauth_parameters(options = {})
        options = options
        #url = options[:request_url] || Services::OnDeego::OauthClient::ACTIONS::CREATE_COMPANY
        url = options[:request_url] || Services::OnDeego::OauthClient::ACTIONS::API_BASE + "/"
        request_uri = URI.parse(url)
        parameters = options[:parameters] || {}
        consumer = OAuth::Consumer.new(property(:ondeego_consumer_key).to_s, property(:ondeego_consumer_secret).to_s)

        #puts "oauth!"
        #puts options.inspect
        RAILS_DEFAULT_LOGGER.info "Request options: " + options.inspect
        http = Net::HTTP.new(request_uri.host, request_uri.port)
        http.use_ssl = (request_uri.scheme == 'https')
        request = Net::HTTP::Post.new(request_uri.path, parameters)
        request.set_form_data(parameters)
        token = OAuth::Token.new(options[:oauth_token], options[:oauth_secret]) if !options[:oauth_token].blank? && !options[:oauth_secret].blank?
        #begin
          #puts "Token: " + token.inspect
          RAILS_DEFAULT_LOGGER.info "Token: " + token.inspect

          request.oauth!(http, consumer, token, parameters.merge({:scheme => "body"}))
          #puts "Request body: " + request.body
          RAILS_DEFAULT_LOGGER.info "Request body: " + request.body.inspect
          params = CGI.parse(request.body)
          signature = params["oauth_signature"][0]
          oauth_helper = request.oauth_helper
          #puts "OAuth params" + oauth_helper.oauth_parameters.inspect
          oauth_helper.oauth_parameters.reject{|k,v| k == "oauth_body_hash"}.merge({"oauth_signature" => signature})
        #rescue
        #  {}
        #end
      end
    end
  end
end

#failureRedirectURL=http://ebento.gera-it-dev.com&city=city&address=address&oauth_nonce=v57x6hJfupyD01KzLHbtwWIiDtBDnlXAnFf4Nw510N0&companyName=test&lastName=lastName&numberEmployeesAllowed=10&oauth_timestamp=1292275346&oauth_signature_method=HMAC-SHA1&countryISOCode=US&successRedirectURL=http://ebento.gera-it-dev.com&phone=12345678&jobTitle=jobTitle&firstName=firstName&oauth_consumer_key=AQ==&companyLogoURL=&oauth_version=1.0&oauth_signature=dKsrBFvXoPREsue3tM8rqWZVEVY=&state=US&email=test@tes.com
#s = POST&http%3A%2F%2Fdev.ondeego.com%3A8443%2Fappcentral%2Fapi%2Fcompany%2Fcreate&address%3Daddress%26city%3Dcity%26companyLogoURL%3D%26companyName%3Dtest%26countryISOCode%3DUS%26email%3Dtest%2540tes.com%26failureRedirectURL%3Dhttp%253A%252F%252Febento.gera-it-dev.com%26firstName%3DfirstName%26jobTitle%3DjobTitle%26lastName%3DlastName%26numberEmployeesAllowed%3D10%26oauth_consumer_key%3DAQ%253D%253D%26oauth_nonce%3Dppgzt1iMU0ri8cAWzddgpzhKR8Fv4XYto9MBDkp8s%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1291984341%26oauth_version%3D1.0%26phone%3D12345678%26state%3DUS%26successRedirectURL%3Dhttp%253A%252F%252Febento.gera-it-dev.com
#      secret = "VRw72NI3SFEKRj7vDk0apv56i3AZoLiSnCcEh95%2B6oM%3D&"
#d = Digest::SHA1
#Digest::HMAC.digest(s, secret, d)
#"\237K\037\n�z1\236gK�Ս�3\027\2208\006"
#Base64.encode64(_).chomp.gsub(/\n/,'')
#"n0sfCtZ6MZ5nS/oT1Y3CMxeQOAY="
