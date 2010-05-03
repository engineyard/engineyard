require 'engineyard/action/util'

module EY
  module Action
    class SSH
      extend Util

      def self.call(name)

        env = account.environment_named(name)
        if env
          Kernel.exec "ssh", "#{env.username}@#{env.app_master.public_hostname}", *ARGV[2..-1]
        else
          EY.ui.warn %|Could not find an environment named "#{name}"|
        end
      end
    end
  end
end
