require 'retries'

module EY
  class Token
    attr_reader :token

    def initialize(token)
      @token = token
    end

    def request(url, opts={})
      opts[:headers] ||= {}
      opts[:headers]["X-EY-Cloud-Token"] = token
      EY.api.request(url, opts)
    end

    def self.authenticate(email = nil, password = nil)
      token = from_file
      return new(token) if token

      EY.ui.info("We need to fetch your API token, please login")
      begin
        email    = EY.ui.ask("Email: ")
        password = EY.ui.ask("Password: ", true)

        auth_response = EY.api.request("/authenticate", :method => "post",
          :params => { :email => email, :password => password })
      rescue EY::Request::InvalidCredentials
        2.retries do
          EY.ui.warn "Invalid username or password, please try again"
        end
        raise EY::Error, "Could not authenticate after three tries, sorry"
      end

      token = auth_response["api_token"]
      to_file(token)
      new(token)
    end

    def self.from_file(file = File.expand_path("~/.eyrc"))
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

    def self.to_file(token, file = File.expand_path("~/.eyrc"))
      require 'yaml'

      data = File.exists?(file) ? YAML.load_file(file) : {}
      if EY.api.default_endpoint?
        data.merge!("api_token" => token)
      else
        data.merge!(EY.api.endpoint => {"api_token" => token})
      end

      File.open(file, "w"){|f| YAML.dump(data, f) }
    end

  end
end
