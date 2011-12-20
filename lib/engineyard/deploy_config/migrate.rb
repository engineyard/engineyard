module EY
  class DeployConfig
    class Migrate

      DEFAULT = 'rake db:migrate'

      def initialize(cli_opts, env_config, ui)
        @cli_opts = cli_opts
        @env_config = env_config
        @ui = ui

        @perform = nil
        @command = nil
      end

      # Returns an array of [perform_migration, migrate_command] on success.
      # Yields the block if no migrate options are set.
      def when_outside_repo
        if perform_from_cli_opts
          if @perform
            @command ||= command_from_opts || DEFAULT
          else
            @command = nil
          end
          [@perform, @command]
        else
          raise RefAndMigrateRequiredOutsideRepo.new(@cli_opts)
        end
      end

      # Returns an array of [perform_migration, migrate_command] on success.
      # Should always return successfully.
      def when_inside_repo
        if perform_from_cli_opts || perform_from_config || perform_from_interaction
          if @perform
            @command ||= command_from_opts || command_from_config || DEFAULT
          else
            @cammond = nil
          end
          [@perform, @command]
        else
          raise MigrateRequired.new(@cli_opts)
        end
      end

      private

      attr_reader :cli_opts, :env_config, :ui

      def command_from_opts
        cli_migrate = cli_opts.fetch('migrate', nil)
        cli_migrate.respond_to?(:to_str) && cli_migrate.to_str
      end

      def command_from_config
        env_config.migrate_command
      end

      def perform_from_cli_opts
        @perform = !!cli_opts.fetch('migrate') { return false } # yields on not found
        true
      end

      def perform_from_config
        @perform = !!env_config.migrate { return false } # yields on not found
        true
      end

      def perform_from_interaction
        if ui.interactive?
          ui.warn "********************************************************************************"
          ui.warn "No default migrate choice for environment: #{env_config.name}"
          ui.warn "Migrate can be turned on / off per-deploy using --migrate or --no-migrate."
          ui.warn "Let's set a default migration choice."
          ui.warn "********************************************************************************"
          @perform = ui.agree('Migrate every deploy by default? ', true)
          env_config.migrate = @perform
          if @perform
            command_from_interaction
          end
          ui.say "#{env_config.path}: migrate settings saved for #{env_config.name}."
          ui.say  "It's a good idea to git commit #{env_config.path} after your deploy completes."
          true
        else
          ui.error "********************************************************************************"
          ui.error "No default migrate choice in ey.yml for environment: #{env_config.name}"
          ui.error "To be safe, ey deploy no longer migrates when no default is set."
          ui.error "Run interactively for step-by-step ey.yml migration setup."
          ui.error "Migrate can be turned on / off per-deploy using --migrate or --no-migrate."
          ui.error "********************************************************************************"
          false
        end
      end

      # only interactively request a command if we interactively requested the perform setting.
      # don't call this outside of the interactive setting (otherwise, why even have a default?)
      def command_from_interaction
        default = env_config.migration_command || DEFAULT
        @command = ui.ask("Migration command? ", false, default)
        env_config.migration_command = @command
        @command
      end
    end
  end
end
