require 'cli/help'

module EY
  module CLI
    class CommandNotFound < StandardError; end

    COMMANDS = {
      "help" => EY::CLI::Help,
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
      usage: ey <command> <args>
      EOF
      COMMANDS.values.each do |cmd|
        if cmd.respond_to?(:short_usage)
          $stderr << "\n\t#{cmd.short_usage}\n"
        end
      end
    end
  end
end