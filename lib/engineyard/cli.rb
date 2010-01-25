Dir[File.dirname(__FILE__)+"/cli/*.rb"].each{|f| require f }

module EY
  module CLI
    class CommandNotFound < StandardError; end

    COMMANDS = {
      "help" => EY::CLI::Help,
      "deploy" => EY::CLI::Deploy,
      "environments" => EY::CLI::Environments,
      "envs" => EY::CLI::Environments
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
      %w(environments deploy help).map{|n| COMMANDS[n] }.each do |cmd|
        if cmd.respond_to?(:short_usage)
          $stderr << "  #{cmd.short_usage}\n"
        end
      end
    end
  end
end