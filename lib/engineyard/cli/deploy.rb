module EY
  module CLI
    class Deploy
      def self.run(args)
        puts "Deploy"
      end

      def self.short_usage
        "ey deploy <environment>: deploy the app in the current directory to <environment>"
      end
    end
  end
end