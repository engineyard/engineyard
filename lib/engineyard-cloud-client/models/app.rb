require 'engineyard-cloud-client/errors'
require 'engineyard-cloud-client/models'
require 'engineyard-cloud-client/collections'

module EY
  class CloudClient
    class App < ApiStruct.new(:id, :name, :repository_uri, :app_type_id)

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

      # An everything-you-need helper to create an App
      def self.create(api, account, name, repository_uri, app_type_id)
        environment = self.new(api, {
          "account" => account,
          "name" => name,
          "repository_uri" => repository_uri,
          "app_type_id" => app_type_id
        })
        environment.create
        environment
      end

      # If successful, returns true and sets +id+ to the new id value
      # If unsuccessful, raises +EY::CloudClient::RequestFailed+
      def create
        # require name, repository_uri, account
        params = {
          "app" => {
            "name"           => name,
            "repository_uri" => repository_uri,
            "app_type_id"    => app_type_id,
          }
        }
        response = api.request("/accounts/#{account.id}/apps", :method => :post, :params => params)
        self.id = response.id
        true
      # rescue EY::CloudClient::RequestFailed => e
        # Examples (multiple fields can have errors)
        # 422 Unprocessable Entity {"errors":{"name":["Application name must not contain spaces or special characters"],"repository_uri":["Git Repository URI malformed. Cannot access relative or file based URIs."]}}

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
