require 'engineyard/action/util'

module EY
  module Action
    class ListEnvironments
      extend Util

      def self.call(all)
        app, envs = app_and_envs(all)
        if app
          EY.ui.say %|Cloud environments for #{app.name}:|
            EY.ui.print_envs(envs, EY.config.default_environment)
        elsif envs
          EY.ui.say %|Cloud environments:|
            EY.ui.print_envs(envs, EY.config.default_environment)
        else
          EY.ui.say %|You do not have any cloud environments.|
        end
      end
    end
  end
end
