module Tools
  module FilterErrorMessages
    def filter_error_messages(skip_errors)
      filtered_errors = self.errors.reject{ |err| skip_errors.to_a.include?(err.first) }
      self.errors.clear
      filtered_errors.each { |err| self.errors.add(*err) }
    end
  end
end
