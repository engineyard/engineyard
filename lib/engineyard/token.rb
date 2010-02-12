module EY
  class Token
    attr_reader :token

    def initialize(token)
      @token = token
    end

    def request(url, opts={})
      opts[:headers] ||= {}
      opts[:headers]["X-EY-Cloud-Token"] = token
      EY::Request.request(url, opts)
    end

    def self.authenticate(email = nil, password = nil, input = $stdin)
      token = from_file
      return new(token) if token

      EY.ui.info("We need to fetch your API token, please login")
      begin
        raise EY::Request::InvalidCredentials
        email    = EY.ui.ask("Email: ")
        password = EY.ui.ask("Password: ", true)

        response = EY::Request.request("/authenticate", :method => "post",
          :params => { :email => email, :password => password })
      rescue EY::Request::InvalidCredentials
        puts "Invalid username or password"
        raise EY::CLI::Exit
      end

      token = response["api_token"]
      to_file(token)
      new(token)
    end

    def self.from_file(file = File.expand_path("~/.eyrc"))
      require 'yaml'
      if File.exists?(file)
        YAML.load_file(file)["api_token"]
      else
        false
      end
    end

    def self.to_file(token, file = File.expand_path("~/.eyrc"))
      require 'yaml'
      File.open(file, "w") do |fp|
        fp.write YAML.dump({"api_token" => token})
      end
    end

  end
end
