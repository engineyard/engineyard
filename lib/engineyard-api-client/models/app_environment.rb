require 'launchy'
require 'engineyard-api-client/errors'

module EY
  class APIClient
    class AppEnvironment < ApiStruct.new(:id, :app, :environment, :perform_migration, :migration_command)

      def initialize(api, attrs)
        super

        raise ArgumentError, 'AppEnvironment created without app!' unless app
        raise ArgumentError, 'AppEnvironment created without environment!' unless environment

        if environment.deployment_configurations
          extract_deploy_config(environment.deployment_configurations[app.name])
        end
      end

      def app=(app_or_hash)
        super App.from_hash(api, app_or_hash)
      end

      def environment=(env_or_hash)
        super Environment.from_hash(api, env_or_hash)
      end

      def account_name
        app.account_name
      end

      def app_name
        app.name
      end

      def environment_name
        environment.name
      end

      def repository_uri
        app.repository_uri
      end

      def to_hierarchy_str
        [account_name, app_name, environment_name].join('/')
      end

      # hack for legacy api.
      def extract_deploy_config(deploy_config)
        if deploy_config
          self.migration_command = deploy_config['migrate']['command']
          self.perform_migration = deploy_config['migrate']['perform']
        end
      end

      def last_deployment
        Deployment.last(api, self)
      end

      def new_deployment(attrs)
        Deployment.from_hash(api, attrs.merge(:app_environment => self))
      end

      def rollback(extra_deploy_hook_options={}, verbose=false)
        environment.bridge!.rollback(
          self,
          config.merge(extra_deploy_hook_options),
          verbose)
      end

      def take_down_maintenance_page(verbose=false)
        environment.bridge!.take_down_maintenance_page(app, verbose)
      end

      def put_up_maintenance_page(verbose=false)
        environment.bridge!.put_up_maintenance_page(app, verbose)
      end

      def configuration
        EY.config.environments[environment.name] || {}
      end
      alias_method :config, :configuration

      def short_environment_name
        environment.name.gsub(/^#{Regexp.quote(app.name)}_/, '')
      end

      def launch
        Launchy.open(environment.bridge!.hostname_url)
      end

    end
  end
end
