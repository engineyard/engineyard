require 'engineyard-cloud-client/models/api_struct'

module EY
  class CloudClient
    class Account < ApiStruct.new(:id, :name)
    end
  end
end
