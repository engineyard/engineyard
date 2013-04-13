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
            @command = nil
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
        @perform = cli_opts.fetch('migrate') { return false } # yields on not found
        true
      end

      def perform_from_config
        @perform = env_config.fetch('migrate') { return perform_implied_via_command_in_config }
        if @perform
          unless command_from_config
            env_config.migration_command = DEFAULT
          end
        end
        true
      end

      # if the command is set in ey.yml and perform isn't explicitly turned off,
      # then we'll write out the old default of migrating always, since that's
      # probably what is expected.
      def perform_implied_via_command_in_config
        if @perfom.nil? && @command = command_from_config
          @perform = true
          env_config.migrate = @perform
          ui.info "********************************************************************************"
          ui.info "#{env_config.path} config for #{env_config.name} has been updated to"
          ui.info "migrate by default to maintain previous expected default behavior."
          ui.info ""
          ui.info "Please git commit #{env_config.path} with these new changes.", :yellow
          ui.info ""
          true
        else
          false
        end
      end

      def perform_from_interaction
        @perform = ui.agree("Run migrations by default on #{env_config.name}? ", true)
        env_config.migrate = @perform
        if @perform
          command_from_interaction
        end
        ui.info "#{env_config.path}: migrate settings saved for #{env_config.name}."
        ui.info "You can override this default with --migrate or --no-migrate."
        ui.info "Please git commit #{env_config.path} with these new changes.", :yellow
        true
      rescue Timeout::Error
        @perform = nil
        @command = nil
        ui.error "Timeout when waiting for input. Maybe this is not a terminal?"
        ui.error "ey deploy no longer migrates when no default is set in ey.yml."
        ui.error "Run interactively for step-by-step ey.yml migration setup."
        ui.error ""
        ui.error "Alternatively, you may add ey.yml to your project directly:"
        ui.error "---"
        ui.error "environments:"
        ui.error "  #{env_config.name}:"
        ui.error "    migrate: true"
        ui.error "    migration_command: 'rake db:migrate'"
        return false
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
