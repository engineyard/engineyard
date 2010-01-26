require 'pp'
module EY
  module CLI
    class Deploy < Command
      def self.run(args)
        pp token.request("/check_token")
        puts "Deploy"
      end

      def self.short_usage
        "ey deploy <environment>: deploy the app in the current directory to <environment>"
      end
    end
  end
end