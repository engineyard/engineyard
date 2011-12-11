require 'engineyard-api-client/errors'

module EY
  class APIClient
    class App < ApiStruct.new(:id, :account, :name, :repository_uri, :environments, :api)

      def self.from_hash(hash)
        super.tap do |app|
          app.environments = Environment.from_array(app.environments, :api => app.api)
          app.account = Account.from_hash(app.account)
        end
      end

      def self.from_array(*)
        Collections::Apps.new(super)
      end

      def sole_environment
        if environments.size == 1
          environments.first
        end
      end

      def sole_environment!
        sole_environment or raise NoSingleEnvironmentError.new(self)
      end

    end
  end
end
