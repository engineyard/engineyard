require 'highline'
require 'engineyard-cloud-client'
require 'engineyard/eyrc'

module EY
  class CLI
    class API
      def self.authenticate(ui)
        ui.info("We need to fetch your API token; please log in.")
        begin
          email    = ui.ask("Email: ")
          password = ui.ask("Password: ", true)
          token    = EY::CloudClient.authenticate(email, password, ui)
          EY::EYRC.load.api_token = token
          token
        rescue EY::CloudClient::InvalidCredentials
          ui.warn "Invalid username or password; please try again."
          retry
        end
      end

      attr_reader :token

      def initialize(endpoint, ui, token = nil)
        @ui = ui
        EY::CloudClient.endpoint = endpoint

        # If the token is specified, we don't ask for authentication when
        # the token is reject, we just exit.
        if @token = token
          @specified = true
          @source = 'token from --api-token'
        elsif @token = ENV['ENGINEYARD_API_TOKEN']
          @specified = true
          @source = 'token from $ENGINEYARD_API_TOKEN'
        elsif @token = EY::EYRC.load.api_token
          @specified = false
          @source = "api_token in #{EY::EYRC.load.path}"
        elsif @token = self.class.authenticate(ui)
          @specified = false
          @source = 'credentials'
        else
          raise EY::Error, "Sorry, we couldn't get your API token."
        end

        @api = EY::CloudClient.new(@token, @ui)
      end

      def respond_to?(*a)
        super or @api.respond_to?(*a)
      end

      protected

      def method_missing(meth, *args, &block)
        if @api.respond_to?(meth)
          @api.send(meth, *args, &block)
        else
          super
        end
      rescue EY::CloudClient::InvalidCredentials
        if @specified
          ui.error "Authentication failed: Invalid #{@source}."
          exit(255)
        else
          ui.warn "Authentication failed: Invalid #{@source}. Retrying..."
          @token = self.class.authenticate(@ui)
          @api = EY::CloudClient.new(@token, @ui)
          retry
        end
      end

    end
  end
end
