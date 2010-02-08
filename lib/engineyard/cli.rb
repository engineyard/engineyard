$:.unshift File.expand_path('../../vendor/thor/lib', __FILE__)
require 'thor'
require 'highline'

require 'cli/command'
require 'cli/deploy'
require 'cli/environments'
require 'cli/help'

module EY
  module CLI
    class CommandNotFound < StandardError; end
    class Exit < StandardError
      attr_reader :code

      def initialize(code = 1)
        @code = code
      end
    end

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

    def self.authenticate(input = $stdin)
      unless token = EY::Token.from_file
        # Ask for user input
        hl = HighLine.new(input)
        hl.say("We need to fetch your API token, please login")
        email = hl.ask("Email: ")
        password = hl.ask("Password: ") {|q| q.echo = "*" }
        token = EY::Token.fetch(email, password)
      end
      token
    rescue EY::Token::InvalidCredentials
      puts "Bad username or password"
      raise Exit
    end
  end
end