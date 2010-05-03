require 'engineyard/action/util'

module EY
  module Action
    class ShowLogs
      extend Util

      def self.call(name)
        env_named(name).logs.each do |log|
          EY.ui.info log.instance_name

          if log.main
            EY.ui.info "Main logs:"
            EY.ui.say  log.main
          end

          if log.custom
            EY.ui.info "Custom logs:"
            EY.ui.say  log.custom
          end
        end

      end
    end
  end
end
