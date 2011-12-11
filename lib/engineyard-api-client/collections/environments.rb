module EY
  class APIClient
    module Collections
      class Environments < Abstract
        self.invalid_error = NoEnvironmentError
        self.ambiguous_error = AmbiguousEnvironmentNameError
      end
    end
  end
end
