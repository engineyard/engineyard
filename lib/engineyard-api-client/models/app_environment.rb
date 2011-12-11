require 'launchy'

module EY
  class APIClient
    class AppEnvironment < ApiStruct.new(:id, :app, :environment, :framework_env, :perform_migration, :migration_command, :api)

      def self.from_hash(hash)
        super.tap do |app_env|
          app_env.app         = App.from_hash(app_env.app, :api => env.api)                 if app_env.app.is_a?(Hash)
          app_env.environment = Environment.from_hash(app_env.environment, :api => env.api) if app_env.environment.is_a?(Hash)
        end
      end

      def last_deployment
        Deployment.last(app, environment, api)
      end

      def deploy(ref, deploy_options={})
        environment.bridge!.deploy(app,
          ref,
          determine_migration_command(deploy_options),
          config.merge(deploy_options['extras']),
          deploy_options['verbose'])
      end

      def rollback(extra_deploy_hook_options={}, verbose=false)
        environment.bridge!.rollback(app,
          config.merge(extra_deploy_hook_options),
          verbose)
      end

      def take_down_maintenance_page(verbose=false)
        environment.bridge!.take_down_maintenance_page(app, verbose)
      end

      def put_up_maintenance_page(verbose=false)
        environment.bridge!.put_up_maintenance_page(app, verbose)
      end

      # If force_ref is a string, use it as the ref, otherwise use it as a boolean.
      def resolve_branch(ref, force_ref=false)
        if String === force_ref
          ref, force_ref = force_ref, true
        end

        if !ref
          default_branch
        elsif force_ref || !default_branch || ref == default_branch
          ref
        else
          raise BranchMismatchError.new(default_branch, ref)
        end
      end

      def configuration
        EY.config.environments[environment.name] || {}
      end
      alias_method :config, :configuration

      def default_branch
        EY.config.default_branch(environment.name)
      end

      def short_environment_name
        environment.name.gsub(/^#{Regexp.quote(app.name)}_/, '')
      end

      def launch
        Launchy.open(environment.bridge!.hostname_url)
      end

      def determine_migration_command(deploy_options)
        # regarding deploy_options['migrate']:
        #
        # missing means migrate how the yaml file says to
        # nil means don't migrate
        # true means migrate w/custom command (if present) or default
        # a string means migrate with this specific command
        return nil if no_migrate?(deploy_options)
        command = migration_command_from_command_line(deploy_options['migrate'])
        unless command
          return nil if no_migrate?(config)
          command = migration_command_from_config
        end
        command = migration_command_from_environment unless command
        command
      end

      private

      def no_migrate?(hash)
        hash.key?('migrate') && hash['migrate'] == false
      end

      def migration_command_from_config
        config['migration_command'] if config['migrate'] || config['migration_command']
      end

      def migration_command_from_command_line(migrate)
        if migrate
          if migrate.respond_to?(:to_str)
            migrate.to_str
          else
            config['migration_command'] || default_migration_command
          end
        end
      end

      def migration_command_from_environment
        migration_command if perform_migration
      end

      def default_migration_command
        'rake db:migrate'
      end
    end
  end
end
