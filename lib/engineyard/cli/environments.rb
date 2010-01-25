module EY
  module CLI
    class Environments < Command
      def self.run(args)
        puts "List of environments"
      end

      def self.short_usage
        "ey environments: list the cloud environments for the app in the current directory"
      end
    end
  end
end