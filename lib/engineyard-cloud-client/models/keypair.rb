require 'engineyard-cloud-client/models/api_struct'

module EY
  class CloudClient
    class Keypair < ApiStruct.new(:id, :name, :public_key)
      def self.all(api)

      end

      def self.create(api, attrs = {})

      end
    end
  end
end
