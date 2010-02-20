module EY
  class Token
    attr_reader :token

    def initialize(token = nil)
      @token ||= token
      @token ||= self.class.from_file
      raise ArgumentError, "EY Cloud API token required" unless @token
    end

    def request(url, opts={})
      opts[:headers] ||= {}
      opts[:headers]["X-EY-Cloud-Token"] = token
      EY.ui.debug("Token", token)
      EY.api.request(url, opts)
    end

    def self.from_cloud(email, password)
      api_token = EY.api.request("/authenticate", :method => "post",
        :params => { :email => email, :password => password })["api_token"]
      to_file(api_token)
      api_token
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
      true
    end

  end # Token
end # EY
