module EY
  class DeployConfig
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
      decide_migrate
      @migrate
    end

    def migrate_command
      decide_migrate
      @migrate_command
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

    def decide_migrate
      return if @migrate_decider
      @migrate_decider = EY::DeployConfig::Migrate.new(@cli_opts, @env_config, @ui)
      @migrate, @migrate_command =
        if in_repo?
          @migrate_decider.when_inside_repo
        else
          @migrate_decider.when_outside_repo
        end
    end
  end
end

require 'engineyard/deploy_config/migrate'
require 'engineyard/deploy_config/ref'
