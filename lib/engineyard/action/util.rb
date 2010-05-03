module EY
  module Action
    module Util

    protected

      def account
        # XXX it stinks that we have to use EY::CLI::API explicitly
        # here; I don't want to have this lateral Action --> CLI reference
        @account ||= EY::Account.new(EY::CLI::API.new)
      end

      def repo
        @repo ||= EY::Repo.new
      end

      def app_and_envs(all_envs = false)
        app = account.app_for_repo(repo)

        if all_envs || !app
          envs = account.environments
          EY.ui.warn(NoAppError.new(repo).message) unless app || all_envs
          [nil, envs]
        else
          envs = app.environments
          if envs.empty?
            EY.ui.warn %|You have no environments set up for the application "#{app.name}"|
              EY.ui.warn %|You can make one at #{EY.config.endpoint}|
          end
          envs.empty? ? [app, nil] : [app, envs]
        end
      end

      def env_named(name)
        env = account.environment_named(name)

        if env.nil?
          raise EnvironmentError, "Environment '#{env_name}' can't be found\n" +
            "You can create it at #{EY.config.endpoint}"
        else
          env
        end
      end

    end
  end
end
