require 'engineyard-api-client/errors'

module EY
  class APIClient
    module Collections
      class Environments < Abstract
        self.invalid_error   = EY::APIClient::NoEnvironmentError
        self.ambiguous_error = EY::APIClient::AmbiguousEnvironmentNameError
      end
    end
  end
end
