require 'pp'
require 'optparse'
module EY
  module CLI
    class Deploy < Command
      def self.run(args)
        config = EY::Config.new
        repo = EY::Repo.new

        commands = []
        while args.first && args.first !~ /^-/
          commands.push(args.shift)
        end

        environment = commands[0]
        branch      = commands[1]

        environment ||= config.default_environment
        branch      ||= (config.default_branch(environment) || repo.current_branch)

        migrate = true
        OptionParser.new do |opts|
          opts.on("-m", "--[no-]migrate", "Run migrations") do |m|
            migrate = m
          end
        end.parse!(args)

        pp environment
        pp branch
        pp migrate
      end

      def self.short_usage
        "ey deploy <environment>: deploy the app in the current directory to <environment>"
      end
    end
  end
end