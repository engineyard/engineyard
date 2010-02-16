module EY
  class Token
    attr_reader :token

    def initialize(token)
      @token = token
    end

    def request(url, opts={})
      begin
        opts[:headers] ||= {}
        opts[:headers]["X-EY-Cloud-Token"] = token
        EY.ui.debug("Token", token)
        EY.api.request(url, opts)
      rescue EY::API::InvalidCredentials
        EY.ui.warn "Credentials rejected, please authenticate again"
        @token = self.class.authenticate
        retry
      end
    end

    class << self
      def saved_token
        api_token = from_file
        if api_token
          new(api_token)
        else
          EY.ui.info("We need to fetch your API token, please login")
          new(authenticate)
        end
      end

      def authenticate(email = nil, password = nil)
        begin
          email    = EY.ui.ask("Email: ")
          password = EY.ui.ask("Password: ", true)

          auth_response = EY.api.request("/authenticate", :method => "post",
            :params => { :email => email, :password => password })
        rescue EY::API::InvalidCredentials
          EY.ui.warn "Invalid username or password, please try again"
          retry
        end

        api_token = auth_response["api_token"]
        to_file(api_token)
        api_token
      end

      def from_file(file = File.expand_path("~/.eyrc"))
        require 'yaml'

        if File.exists?(file)
          data = YAML.load_file(file)
          if EY.api.default_endpoint?
            data["api_token"]
          else
            (data[EY.api.endpoint] || {})["api_token"]
          end
        else
          false
        end
      end

      def to_file(token, file = File.expand_path("~/.eyrc"))
        require 'yaml'

        data = File.exists?(file) ? YAML.load_file(file) : {}
        if EY.api.default_endpoint?
          data.merge!("api_token" => token)
        else
          data.merge!(EY.api.endpoint => {"api_token" => token})
        end

        File.open(file, "w"){|f| YAML.dump(data, f) }
      end
    end # class methods

  end # Token
end # EY
