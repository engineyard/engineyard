require 'thor'
require 'engineyard/cli/thor_fixes'

module EY
  class Thor < ::Thor
    def self.start(original_args=ARGV, config={})
      @@original_args = original_args
      super
    end

    no_tasks do
      def subcommand_args
        @@original_args[1..-1]
      end

      def self.subcommand(subcommand, subcommand_class)
        define_method(subcommand) { |*_| subcommand_class.start(subcommand_args) }
      end
    end

    protected

    def self.exit_on_failure?
      true
    end

    def api
      @api ||= EY::CLI::API.new
    end

    def repo
      @repo ||= EY::Repo.new
    end

    # if an app is supplied, it is used as a constraint for implied environment lookup
    def fetch_environment(env_name, app = nil)
      env_name ||= EY.config.default_environment
      if env_name
        (app || api).environments.match_one!(env_name)
      else
        (app || api.app_for_repo!(repo)).sole_environment!
      end
    end

    def get_apps(all_apps = false)
      if all_apps
        api.apps
      else
        [api.app_for_repo(repo)].compact
      end
    end
  end
end
