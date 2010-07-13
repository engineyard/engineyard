module EY
  module Collection
    class Environments < Abstract
      self.invalid_error = NoEnvironmentError
      self.ambiguous_error = AmbiguousEnvironmentNameError
    end
  end
end
