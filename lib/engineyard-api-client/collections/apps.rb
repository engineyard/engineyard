module EY
  class APIClient
    module Collections
      class Apps < Abstract
        self.invalid_error = InvalidAppError
        self.ambiguous_error = AmbiguousAppNameError
      end
    end
  end
end
