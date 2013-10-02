module EY
  class DeployConfig
    MIGRATE = 'rake db:migrate --trace'

    def initialize(cli_opts, env_config, repo, ui)
      @cli_opts = cli_opts
      @env_config = env_config
      @repo = repo
      @ui = ui
    end

    def ref
      @ref ||= decide_ref
    end

    def migrate
      @migrate ||= @cli_opts.fetch('migrate') do
        if in_repo?
          @env_config.migrate
        else
          raise RefAndMigrateRequiredOutsideRepo.new(@cli_opts)
        end
      end
    end

    def migrate_command
      return @command if defined? @command

      if migrate
        @command = migrate.respond_to?(:to_str) && migrate.to_str
        @command ||= in_repo? ? @env_config.migration_command : MIGRATE
      else
        @command = nil
      end

      @command
    end

    def verbose
      @cli_opts.fetch('verbose') { in_repo? && @env_config.verbose }
    end

    def extra_config
      @cli_opts.fetch('config', {})
    end

    private

    # passing an app means we assume PWD is not the app.
    def in_repo?
      @cli_opts['app'].nil? || @cli_opts['app'] == ''
    end

    def decide_ref
      ref_decider = EY::DeployConfig::Ref.new(@cli_opts, @env_config, @repo, @ui)
      if in_repo?
        ref_decider.when_inside_repo
      else
        ref_decider.when_outside_repo
      end
    end
  end
end

require 'engineyard/deploy_config/ref'
