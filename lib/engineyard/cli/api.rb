require 'highline'
require 'engineyard-cloud-client'
require 'engineyard/eyrc'

module EY
  class CLI
    class API
      USER_AGENT = "EngineYard/#{EY::VERSION}"

      attr_reader :token

      def initialize(endpoint, ui, token = nil)
        @client = EY::CloudClient.new(:endpoint => endpoint, :output => ui.out, :user_agent => USER_AGENT)
        @ui = ui
        @eyrc = EY::EYRC.load
        token_from('--api-token') { token } ||
          token_from('$ENGINEYARD_API_TOKEN') { ENV['ENGINEYARD_API_TOKEN'] } ||
          token_from(@eyrc.path, false) { @eyrc.api_token } ||
          authenticate ||
          token_not_loaded
      end

      def respond_to?(*a)
        super or @client.respond_to?(*a)
      end

      protected

      def method_missing(meth, *args, &block)
        if @client.respond_to?(meth)
          with_reauthentication { @client.send(meth, *args, &block) }
        else
          super
        end
      end

      def with_reauthentication
        begin
          yield
        rescue EY::CloudClient::InvalidCredentials
          if @specified || !@ui.interactive?
            # If the token is specified, we raise immediately if it is rejected.
            raise EY::Error, "Authentication failed: Invalid #{@source}."
          else
            @ui.warn "Authentication failed: Invalid #{@source}."
            authenticate
            retry
          end
        end
      end

      # Get the token from the provided block, saving it if it works.
      # Specified will help us know what to do if loading the token fails.
      # Returns true if it gets a token.
      # Returns false if there is no token.
      def token_from(source, specified = true)
        token = yield
        if token
          @client.token = token
          @specified    = specified
          @source       = "token from #{source}"
          @token        = token
          true
        else
          false
        end
      end

      # Load the token from EY Cloud if interactive and
      # token wasn't explicitly specified previously.
      def authenticate
        if @specified
          return false
        end

        @source    = "credentials"
        @specified = false

        @ui.info "We need to fetch your API token; please log in."
        begin
          email  = @ui.ask("Email: ")
          passwd = @ui.ask("Password: ", true)
          @token = @client.authenticate!(email, passwd)
          @eyrc.api_token = @token
          true
        rescue EY::CloudClient::InvalidCredentials
          @ui.warn "Authentication failed. Please try again."
          retry
        end
      end

      # Occurs when all avenues for getting the token are exhausted.
      def token_not_loaded
        raise EY::Error, "Sorry, we couldn't get your API token."
      end
    end
  end
end
