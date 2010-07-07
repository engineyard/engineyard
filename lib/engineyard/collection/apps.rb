module EY
  module Collection
    class Apps < Abstract
      self.invalid_error = InvalidAppError
      self.ambiguous_error = AmbiguousAppName
    end
  end
end
