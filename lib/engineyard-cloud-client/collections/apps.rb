require 'engineyard-cloud-client/errors'

module EY
  class CloudClient
    module Collections
      class Apps < Abstract
        self.invalid_error   = EY::CloudClient::InvalidAppError
        self.ambiguous_error = EY::CloudClient::AmbiguousAppNameError
      end
    end
  end
end
