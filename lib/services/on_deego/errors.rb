module Services
  module OnDeego
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
      
      class OnDeegoError < StandardError; end
      class ServiceNotAvailable < OnDeegoError
        def initialize
          super("OnDeego is not available")
        end
      end
      class CompanyExists < OnDeegoError
        def initialize
          super("Such company is already exists in OnDeego Service")
        end
      end
      class EmployeeExists < OnDeegoError 
        def initialize
          super("Such employee is already exists in OnDeego Service")
        end
      end
      class LoginFailed < OnDeegoError 
        def initialize
          super("Login to OnDeego Service failed")
        end
      end
      class OAuthGetAccessTokenFailed < OnDeegoError
        def initialize
          super("OAuth Get Access Token failed")
        end
      end
      class OAuthError < OnDeegoError
        def initialize(exception_class)
          super(Messages::TO_MESSAGE[exception_class])
        end
      end
      class GenerickError < OnDeegoError; end
    end
  end
end
