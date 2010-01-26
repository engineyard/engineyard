require 'highline'

module EY
  module CLI
    module Authentication
      def self.get_token
        unless token = EY::Token.from_file
          # Ask for user input
          hl = HighLine.new
          hl.say("We need to fetch your API token, please login")
          email = hl.ask("Email: ")
          password = hl.ask("Password: ") {|q| q.echo = "*" }
          token = EY::Token.fetch(email, password)
        end
        token
      rescue EY::Token::InvalidCredentials
        puts "Bad username or password"
        exit(1)
      end
    end
  end
end
