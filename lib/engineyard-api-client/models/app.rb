require 'engineyard-api-client/errors'

module EY
  class APIClient
    class App < ApiStruct.new(:id, :name, :repository_uri)

      attr_reader :app_environments, :account

      def self.from_array(*)
        Collections::Apps.new(super)
      end

      def initialize(api, attrs)
        super

        @account = Account.from_hash(api, attrs['account']) if attrs['account']
        if attrs['environments']
          app_env_hashes = attrs['environments'].map { |env| {'app' => self, 'environment' => env} }
          @app_environments = AppEnvironment.from_array(api, app_env_hashes)
        end
      end

      def sole_environment
        if environments.size == 1
          environments.first
        end
      end

      def sole_environment!
        sole_environment or raise NoSingleEnvironmentError.new(self)
      end

      def account_name
        account && account.name
      end

      def environments
        (app_environments || []).map { |app_env| app_env.environment }
      end

    end
  end
end
