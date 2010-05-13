require 'engineyard/action/util'

module EY
  module Action
    class Rebuild
      extend Util

      def self.call(name)
        env = fetch_environment_by_name(name) || fetch_environment_from_app
        EY.ui.debug("Rebuilding #{env.name}")
        env.rebuild
      end

      private
      def self.fetch_environment_by_name(name)
        if name
          env = api.environment_named(name)
          return env if env
          raise NoEnvironmentError.new(name)
        end
      end

      def self.fetch_environment_from_app
        repo = Repo.new
        app = api.app_for_repo(repo) or raise NoAppError.new(repo)
        env = app.one_and_only_environment or raise EnvironmentError, "Unable to determine a single environment for the current application (found #{app.environments.size} environments)"
        env
      end
    end
  end
end
