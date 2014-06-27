module Services
  module OnDeego
    class OauthClient

      OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

       #API 2
      module ACTIONS
        API_BASE = property(:on_deego_api)
        CREATE_COMPANY = "#{API_BASE}/api/company/create"
        CREATE_EMPLOYEE = "#{API_BASE}/api/employee/create"
        ACCESS_TOKEN    = "#{API_BASE}/account/OAuthGetReflexiveAccessToken"
        LOGIN           = "#{API_BASE}/account/OAuthLogin"
        DELETE_COMPANY  = "#{API_BASE}/api/company/delete"
        DELETE_EMPLOYEE = "#{API_BASE}/api/employee/delete"
        UPDATE_COMPANY  = "#{API_BASE}/api/company/update"
        UPDATE_EMPLOYEE = "#{API_BASE}/api/employee/update"
      end

      attr_reader :oauth_hash

      def initialize options = {}
        @consumer_key = property(:ondeego_consumer_key).to_s
        @consumer_secret = property(:ondeego_consumer_secret).to_s
        @oauth_token = options[:oauth_token]
        @oauth_secret = options[:oauth_secret]
        @oauth_hash = {}
        @logger = Tools::ApiLogger.new :name => options[:log_name] || "ondeego_oauth"
        @logger.start_logging
      end

      def get_access_token(ondeeego_user_id, options = {})
        url = options[:request_url] || Services::OnDeego::OauthClient::ACTIONS::API_BASE
        consumer = OAuth::Consumer.new(@consumer_key, @consumer_secret, {:site => url,
                                       :access_token_path => Services::OnDeego::OauthClient::ACTIONS::ACCESS_TOKEN})
        begin
          token = consumer.get_access_token(nil, {}, "userId" => ondeeego_user_id)
        rescue OAuth::Unauthorized, RestClient::InternalServerError, RestClient::BadGateway => e
          @logger.put "Exception: #{e.class.name} #{e.backtrace[0..50]}"
          @logger.put "Was requested:\nconsumer_key=#{@consumer_key}&url=#{url}&userId=#{ondeeego_user_id}"
          raise Services::OnDeego::Errors::OAuthGetAccessTokenFailed.new
        rescue Exception, Timeout::Error => e
          @logger.put "Exception: #{e.class.name} #{e.backtrace[0..50]}"
          @logger.put "Was requested:\nconsumer_key=#{@consumer_key}&url=#{url}&userId=#{ondeeego_user_id}"
          raise Services::OnDeego::Errors::GenerickError.new( "Unknown Error, please take a look at log files for more details" )
        ensure
          @logger.stop_logging
        end
        token
      end

      def update_company options = {}
        @logger.put "Update company"
        request_by_post( Services::OnDeego::OauthClient::ACTIONS::UPDATE_COMPANY, options )
      end

      def update_employee options = {}
        @logger.put "Update employee"
        request_by_post( Services::OnDeego::OauthClient::ACTIONS::UPDATE_EMPLOYEE, options )
      end

      def delete_company options = {}
        @logger.put "Delete company"
        request_by_post( Services::OnDeego::OauthClient::ACTIONS::DELETE_COMPANY, options )
      end

      def delete_employee options = {}
        @logger.put "Delete employee"
        request_by_post( Services::OnDeego::OauthClient::ACTIONS::DELETE_EMPLOYEE, options )
      end

      private
        def request_by_post( action, additional_parameters = {} )
          begin
            @oauth_hash = Services::OnDeego::OauthHelper.oauth_parameters(:request_url => action,
                                                                :oauth_token => @oauth_token,
                                                                :oauth_secret => @oauth_secret,
                                                                :parameters => additional_parameters)
            #puts "Params #{@oauth_hash.merge( additional_parameters ).inspect}"
            @logger.put "Params #{@oauth_hash.merge( additional_parameters ).inspect}"
            body = RestClient.post(action, @oauth_hash.merge( additional_parameters ), {"Content-Type" => 'application/x-www-form-urlencoded'})
            @logger.put "Answer #{body.inspect}"
            body
          rescue RestClient::InternalServerError, RestClient::Unauthorized, RestClient::BadGateway,
                 RestClient::BadRequest, RestClient::Forbidden, RestClient::ResourceNotFound => e
            @logger.put "Exception: #{e.class.name} #{e.backtrace[0..25]}"
            @logger.put "Was requested:\n" + action + "?" + @oauth_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            #puts "Exception: #{e.class.name} #{e.backtrace[0..25]}"
            #puts "Was requested:\n" + action + "?" + @oauth_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            raise Services::OnDeego::Errors::OAuthError.new(e.class)
          rescue Exception, Timeout::Error => e
            @logger.put "Exception: #{e.class.name} #{e.backtrace[0..50]}"
            @logger.put "Was requested:\n"  + action + "?" + @oauth_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            #puts "Exception: #{e.class.name} #{e.backtrace[0..50]}"
            #puts "Was requested:\n"  + action + "?" + @oauth_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")
            raise Services::OnDeego::Errors::GenerickError.new( "Unknown Error, please take a look at log files for more details" )
          ensure
            @logger.stop_logging
          end
        end

    end
  end
end
