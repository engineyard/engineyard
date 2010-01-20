require 'cli/help'
require 'cli/deploy'

module EY
  module CLI
    class CommandNotFound < StandardError; end

    COMMANDS = {
      "help" => EY::CLI::Help,
      "deploy" => EY::CLI::Deploy,
    }

    def self.command_to_class(command)
      if klass = COMMANDS[command]
        klass
      else
        raise CommandNotFound
      end
    end

    def self.usage
      $stderr << %{usage: ey <command> <args>\n}
      %w(deploy help).map{|n| COMMANDS[n] }.each do |cmd|
        if cmd.respond_to?(:short_usage)
          $stderr << "  #{cmd.short_usage}\n"
        end
      end
    end
  end
end