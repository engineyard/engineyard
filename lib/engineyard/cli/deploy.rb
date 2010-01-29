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
        default_branch = config.default_branch(environment)
        branch      ||= (default_branch || repo.current_branch)

        options = parse_args(args)

        if !options[:force] && !check_default_branch(branch, default_branch)
          $stderr << %|You are trying to deploy branch "#{branch}", but your deploy branch is set to "#{default_branch}". if you are sure, use —-force\n|
          raise EY::CLI::Exit
        end

        pp environment
        pp branch
        pp options[:migrate]
      end

      def self.parse_args(args)
        # Defaults
        options = {
          :migrate => true,
          :force => false,
        }

        OptionParser.new do |opts|
          opts.on("-m", "--[no-]migrate", "Run migrations") do |migrate|
            options[:migrate] = migrate
          end

          opts.on("-f", "--[no-]force", "Force a deploy of the specified branch") do |force|
            options[:force] = force
          end
        end.parse!(args)

        options
      end

      def self.check_default_branch(branch, default_branch)
        return true unless default_branch
        return false unless branch == default_branch
        true
      end

      def self.short_usage
        "ey deploy <environment>: deploy the app in the current directory to <environment>"
      end
    end
  end
end