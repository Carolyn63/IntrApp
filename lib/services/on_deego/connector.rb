
require 'net/http'
require 'uri'

module Services
  module OnDeego
    class Connector

      @@api_base = property(:on_deego_api)

      @@register_action      = "#{@@api_base}/register"
      @@devices_action       = "#{@@api_base}/devices"
      @@oses_action          = "#{@@api_base}/deviceOSList"
      @@country_codes_action = "#{@@api_base}/countries"
      @@login_action         = "#{@@api_base}/login"

      def self.login_action
        @@login_action
      end

      def initialize options = {}
        @smb_login = options[:smb_login]
        @smb_password = options[:smb_password]
        @request_hash = { 'SMBusername' => @smb_login, 'SMBpassword' => @smb_password  }
        @logger = Tools::ApiLogger.new :name => options[:log_name] || "ondeego"
        @logger.start_logging
      end

      def create_company options = {}
        #puts options.inspect
        @logger.put "Create company"
        json_values = request_by_post( @@register_action, options.merge( 'regType' => "IT" ) )
        @logger.put "Answer #{json_values.inspect}"
        @logger.stop_logging
        raise Services::OnDeego::Errors::GenerickError.new( json_values["message"] ) if json_values["status"] == "error"
      end

      def create_employee options = {}
        #puts options.inspect
        @logger.put "Create employee"
        json_values = request_by_post( @@register_action, options.merge( 'regType' => "employee" ) )
        @logger.put "Answer #{json_values.inspect}"
        @logger.stop_logging
        raise Services::OnDeego::Errors::GenerickError.new( json_values["message"] ) if json_values["status"] == "error"
      end

      def devices
        json_values = request_by_post( @@devices_action )
      end

      def oses platform
        json_values = request_by_post( @@oses_action, { "platform" => platform } )
      end

      def country_codes
        json_values = request_by_post( @@country_codes_action )
      end

      def login options = {}
        @logger.put "Login"
        json_values = request_by_post( @@login_action, options.merge( "role" => "IT" ) )
        @logger.put "Answer #{json_values.inspect}"
      end

      private
        def request_by_post( action, additional_parameters = {} )
          begin
            @request_hash.merge( additional_parameters ).inspect
            @logger.put "Params #{@request_hash.merge( additional_parameters ).inspect}"
            body = RestClient.post action, @request_hash.merge( additional_parameters )
            values = JSON.parse( body )
          rescue RestClient::InternalServerError => e
            RAILS_DEFAULT_LOGGER.info "Exception: " + e.class.name
            RAILS_DEFAULT_LOGGER.info "Was requested:\n" + action + "?" + additional_parameters.to_a.map{|fd| fd.join("=") }.join("&")
            RAILS_DEFAULT_LOGGER.info "Body:\n" + e.http_body
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + action + "?" + additional_parameters.to_a.map{|fd| fd.join("=") }.join("&")
            @logger.put "Body:\n" + e.http_body
            @logger.stop_logging
            raise Services::OnDeego::Errors::GenerickError.new( "OnDeego Service Error, please take a look at log files for more details" )
          rescue Exception, Timeout::Error => e
            RAILS_DEFAULT_LOGGER.info "Exception: " + e.class.name
            RAILS_DEFAULT_LOGGER.info "Was requested:\n" + action + "?" + additional_parameters.to_a.map{|fd| fd.join("=") }.join("&")
            @logger.put "Exception: #{e.class.name} #{e.backtrace[0..50]}"
            @logger.put "Was requested:\n" + action + "?" + additional_parameters.to_a.map{|fd| fd.join("=") }.join("&")
            @logger.stop_logging
            raise Services::OnDeego::Errors::GenerickError.new( "Unknown Error, please take a look at log files for more details" )
          end
        end
=begin
### first implementation
        def request_by_post( action, additional_parameters = {} )
          url = URI.parse(  action )
          puts @request_hash.merge( additional_parameters ).inspect
          data = @request_hash.merge( additional_parameters ).to_a.map{|fd| fd.join("=") }.join("&")

          begin
            http = Net::HTTP.new( url.host, url.port )
            http.use_ssl = true
            res = http.post( url.path, data, {} )
          rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
            Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
            puts e.inspect
            puts e.body
          end
          puts res.body
          case res
          when Net::HTTPSuccess, Net::HTTPRedirection
            puts res.body
          else
            #res.error!
          end
        end
=end
    end
  end
end
