require 'engineyard-cloud-client/models'

module EY
  class CloudClient
    class User < ApiStruct.new(:id, :name, :email)
    end
  end
end
