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

      def initialize(endpoint, ui)
        @ui = ui
        EY::CloudClient.endpoint = endpoint

        @token = ENV['ENGINEYARD_API_TOKEN'] if ENV['ENGINEYARD_API_TOKEN']
        @token ||= EY::EYRC.load.api_token
        @token ||= self.class.authenticate(ui)

        unless @token
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
        ui.warn "Authentication failed."
        @token = self.class.authenticate(@ui)
        @api = EY::CloudClient.new(@token, @ui)
        retry
      end

    end
  end
end
