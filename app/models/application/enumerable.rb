module Application::Enumerable
  module Status
    ACTIVE = 0
    DEACTIVATED = 1

    ALL = [ACTIVE, DEACTIVATED]

    LIST = [
      ['Active', ACTIVE],
      ['Deactivated', DEACTIVATED]
    ]

    TO_LIST = { ACTIVE => 'Active', DEACTIVATED => 'Deactivated' }
  end

  # def self.included(base)
  #   base.include InstanceMethods
  # end

  # module InstanceMethods
  #   module Status
  #     ACTIVE = 0
  #     DEACTIVATED = 1

  #     ALL = [ACTIVE, DEACTIVATED]

  #     LIST = [
  #       ['Active', ACTIVE],
  #       ['Deactivated', DEACTIVATED]
  #     ]

  #     TO_LIST = { ACTIVE => 'Active', DEACTIVATED => 'Deactivated' }
  #   end
  # end
end
