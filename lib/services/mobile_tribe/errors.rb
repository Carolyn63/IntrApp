module Services
  module MobileTribe
    module Errors
      class MobileTribeError < StandardError; end
      class ServiceNotAvailable < MobileTribeError
        def initialize
          super("MobileTribe is not available")
        end
      end
      class UserExists < MobileTribeError
        def initialize
          super("User already exists in MobileTribe Service")
        end
      end
      class RegisterCredentialsError < MobileTribeError
        def initialize
          super("Employee already exists in MobileTribe Service")
        end
      end
      class LoginFailed < MobileTribeError
        def initialize
          super("Login to MobileTribe Service failed")
        end
      end
      class Unauthorized < MobileTribeError
        def initialize
          super("Login to MobileTribe Service failed - wrong login or password")
        end
      end
      class GenerickError < MobileTribeError; end
    end
  end
end
