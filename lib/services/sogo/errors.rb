module Services
  module Sogo
    module Errors

      module Messages
        TO_MESSAGE = {
          RestClient::InternalServerError => "Server error",
          RestClient::Unauthorized => "Authorization failed",
          RestClient::Forbidden => "Authorization failed",
          RestClient::BadGateway => "Bad request",
          RestClient::BadRequest => "Invalid request URI, header, or parameter name/value",
          RestClient::ResourceNotFound => "Resource not found"
        }
      end
      
      class OnWrapperError < StandardError; end
      class NotFound < OnWrapperError
        def initialize
          super("User not found")
        end
      end
      class ConnectionError < OnWrapperError
        def initialize
          super("Connection error")
        end
      end
      class ServerError < OnWrapperError
        def initialize
          super("Internal Server error. Please, contact with admin")
        end
      end
      class SaveUserError < OnWrapperError
        def initialize(message)
          error_message = "Create/Update mail and sogo accounts error(s): "
          unless message.blank?
            parse_errors = Hash.from_xml(message)
            errors = []
            parse_errors["errors"].each do |attr, error|
             errors += error["error"].to_a
            end
            error_message += errors.join("; ")
          end
          super(error_message)
        end
      end
      class GenerickError < OnWrapperError; end
    end
  end
end
