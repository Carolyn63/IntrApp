module Services
  module IppbxApi
    module Errors
      class IppbxError < StandardError; end
      class ConnectionUnAvailable < IppbxError
        def initialize
          super("Ippbx Server is not available")
        end
      end
      class GenerickError < IppbxError; end
    end
  end
end
