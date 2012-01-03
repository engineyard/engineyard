require 'engineyard-cloud-client/models/api_struct'

module EY
  class CloudClient
    class Keypair < ApiStruct.new(:id, :name, :public_key)

      def self.from_array(*)
        Collections::Keypairs.new(super)
      end


      def self.all(api)
        self.from_array(self, api.request('/keypairs')["keypairs"])
      end

      def self.create(api, attrs = {})

      end
    end
  end
end
