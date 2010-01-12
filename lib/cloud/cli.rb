module EY
  module Cloud
    module CLI
      class CommandNotFound < StandardError; end
      
      COMMANDS = {
        "setup" => EY::Cloud::Setup,
        "help" => EY::Cloud::Help,
      }
      
      def self.command_to_class(command)
        if klass = COMMANDS[command]
          klass 
        else
          raise CommandNotFound
          usage
          exit(1)
        end
      end
      
      def self.usage
        $stderr << <<-EOF
usage: cloud <command> <args>
        EOF
        COMMANDS.values.each do |cmd|
          if cmd.respond_to?(:short_usage)
            $stderr << "\n\t#{cmd.short_usage}\n"
          end
        end
      end
    end
  end
end