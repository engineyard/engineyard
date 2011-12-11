require 'engineyard-api-client/errors'

module EY
  class APIClient
    module Collections
      class Apps < Abstract
        self.invalid_error   = EY::APIClient::InvalidAppError
        self.ambiguous_error = EY::APIClient::AmbiguousAppNameError
      end
    end
  end
end
