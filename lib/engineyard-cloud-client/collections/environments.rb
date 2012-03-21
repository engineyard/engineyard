require 'engineyard-cloud-client/errors'

module EY
  class CloudClient
    module Collections
      class Environments < Abstract
        self.invalid_error   = EY::CloudClient::NoEnvironmentError
        self.ambiguous_error = EY::CloudClient::AmbiguousEnvironmentNameError
      end
    end
  end
end
