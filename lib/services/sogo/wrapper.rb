
require 'net/http'
require 'uri'

module Services
  module Sogo
    class Wrapper

      @@api_base = property(:wrapper_api)


      def initialize options = {}
        @wrapper_login = options[:wrapper_login] || property(:wrapper_login)
        @wrapper_password = options[:wrapper_password] || property(:wrapper_password)
        @basic_auth = {:user => @wrapper_login, :password => @wrapper_password}
        @logger = Tools::ApiLogger.new :name => options[:log_name] || "wrapper"
        @logger.start_logging
      end

      def create_user options = {}
        @logger.put "Create user"
        answer = request_by_post( @@api_base,  options)
        @logger.put "Answer #{answer.inspect}"
        @logger.stop_logging
        answer
      end

      def update_user options = {}
        @logger.put "Update user"
        answer = request_by_post( @@api_base + "/#{options[:email]}",  options)
        @logger.put "Answer #{answer.inspect}"
        @logger.stop_logging
        answer
      end

      def delete_user options = {}
        #puts options.inspect
        @logger.put "Delete user"
        answer = request_by_get_or_delete( @@api_base + "/#{options[:email]}",  options.merge(:method => :delete))
        @logger.put "Answer #{answer.inspect}"
        @logger.stop_logging
        answer
      end

      def delete_all_user options = {}
        @logger.put "Delete all user"
        answer = request_by_get_or_delete( @@api_base + "/delete_all/#{options[:domain]}",  options.merge(:method => :get))
        @logger.put "Answer #{answer.inspect}"
        @logger.stop_logging
        answer
      end

      def show_user options = {}
        @logger.put "Update user"
        answer = request_by_get_or_delete( @@api_base + "/#{options[:email]}",  options.merge(:method => :get))
        @logger.put "Answer #{answer.inspect}"
        @logger.stop_logging
        answer
      end

      private
        def request_by_post( action, additional_parameters = {} )
          begin
            params = {"email" => additional_parameters[:email],
                      "password" => additional_parameters[:password],
                      "crypted_password" => additional_parameters[:crypted_password],
                      "full_name" => additional_parameters[:full_name]
                      }.to_xml(:skip_instruct => true, :root => 'user')
            #puts "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            resource = RestClient::Resource.new(action, @basic_auth.merge( :timeout => 30, :open_timeout => 10))
            body = resource.post(params, :content_type => "xml")
            @logger.put "Body #{body.inspect}"
            body
          rescue RestClient::BadRequest => e
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Body:\n" + e.http_body.to_s
            @logger.stop_logging
            raise Services::Sogo::Errors::SaveUserError.new( e.http_body.to_s )
          rescue RestClient::Unauthorized => e
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Body:\n" + e.http_body.to_s
            @logger.stop_logging
            raise Services::Sogo::Errors::NotFound.new
          rescue Errno::ECONNREFUSED, Timeout::Error, RestClient::RequestTimeout => e
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Body:\n" + e.http_body.to_s if e.respond_to?(:http_body)
            @logger.stop_logging
            raise Services::Sogo::Errors::ConnectionError.new
          rescue RestClient::InternalServerError => e
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Body:\n" + e.http_body.to_s if e.respond_to?(:http_body)
            @logger.stop_logging
            raise Services::Sogo::Errors::ServerError.new
          rescue Exception => e
            @logger.put "Exception: #{e.class.name} #{e.backtrace[0..50]}"
            @logger.put "Was requested:\n" + "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Body:\n" + e.http_body.to_s if e.respond_to?(:http_body)
            @logger.stop_logging
            raise Services::Sogo::Errors::GenerickError.new( "Unknown Error, please take a look at log files for more details" )
          end
        end

        def request_by_get_or_delete( action, additional_parameters = {} )
          begin
            params = additional_parameters
            #puts "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            resource = RestClient::Resource.new(action, @basic_auth.blank? ? {} : @basic_auth)
            if additional_parameters[:method] == :get
              body = resource.get(:content_type => "xml")
            elsif additional_parameters[:method] == :delete
              body = resource.delete(:content_type => "xml")
            end
            @logger.put "Body #{body.inspect}"
            body
          rescue RestClient::Unauthorized => e
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Body:\n" + e.http_body.to_s
            @logger.stop_logging
            raise Services::Sogo::Errors::NotFound.new
          rescue Errno::ECONNREFUSED, Timeout::Error, RestClient::RequestTimeout => e
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Body:\n" + e.http_body.to_s if e.respond_to?(:http_body)
            @logger.stop_logging
            raise Services::Sogo::Errors::ConnectionError.new
          rescue RestClient::InternalServerError => e
            @logger.put "Exception: " + e.class.name
            @logger.put "Was requested:\n" + "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Body:\n" + e.http_body.to_s
            @logger.stop_logging
            raise Services::Sogo::Errors::ServerError.new
          rescue Exception => e
            @logger.put "Exception: #{e.class.name} #{e.backtrace[0..50]}"
            @logger.put "Was requested:\n" + "Action #{action} Auth #{@basic_auth.inspect} Params #{params.inspect}"
            @logger.put "Body:\n" + e.http_body.to_s if e.respond_to?(:http_body)
            @logger.stop_logging
            raise Services::Sogo::Errors::GenerickError.new( "Unknown Error, please take a look at log files for more details" )
          end
        end

    end
  end
end
