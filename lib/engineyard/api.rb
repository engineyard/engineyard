module EY
  class API
    attr_reader :token

    def initialize(token = nil)
      @token ||= token
      @token ||= self.class.from_file
      raise ArgumentError, "EY Cloud API token required" unless @token
    end

    def ==(other)
      raise ArgumentError unless other.is_a?(self.class)
      self.token == other.token
    end

    def request(url, opts={})
      opts[:headers] ||= {}
      opts[:headers]["X-EY-Cloud-Token"] = token
      EY.ui.debug("Token", token)
      self.class.request(url, opts)
    end

    class InvalidCredentials < EY::Error; end
    class RequestFailed < EY::Error; end

    def self.request(path, opts={})
      EY.library 'rest_client'
      EY.library 'json'

      url = EY.config.endpoint + "/api/v2" + path
      method = ((meth = opts.delete(:method)) && meth.to_s || "get").downcase.to_sym
      params = opts.delete(:params) || {}
      headers = opts.delete(:headers) || {}
      headers["Accept"] ||= "application/json"

      begin
        EY.ui.debug("Request", method.to_s.upcase + " " + url)
        case method
        when :get, :delete, :head
          url += "?#{RestClient::Payload::UrlEncoded.new(params)}"
          resp = RestClient.send(method, url, headers)
        else
          resp = RestClient.send(method, url, params, headers)
        end
      rescue RestClient::Unauthorized
        raise InvalidCredentials
      rescue Errno::ECONNREFUSED
        raise RequestFailed, "Could not reach the cloud API"
      rescue RestClient::ResourceNotFound
        raise RequestFailed, "The requested resource could not be found"
      rescue RestClient::RequestFailed => e
        raise RequestFailed, "#{e.message}"
      end
      raise RequestFailed, "Response body was empty" if resp.body.empty?

      begin
        data = JSON.parse(resp.body)
        EY.ui.debug("Response", data)
      rescue JSON::ParserError
        EY.ui.debug("Raw response", resp.body)
        raise RequestFailed, "Response was not valid JSON."
      end

      data
    end

    def self.from_cloud(email, password)
      api_token = request("/authenticate", :method => "post",
        :params => { :email => email, :password => password })["api_token"]
      to_file(api_token)
      api_token
    end

    def self.from_file(file = File.expand_path("~/.eyrc"))
      return false unless File.exists?(file)

      require 'yaml'

      data = YAML.load_file(file)
      if EY.config.default_endpoint?
        data["api_token"]
      else
        (data[EY.config.endpoint] || {})["api_token"]
      end
    end

    def self.to_file(token, file = File.expand_path("~/.eyrc"))
      require 'yaml'

      data = File.exists?(file) ? YAML.load_file(file) : {}
      if EY.config.default_endpoint?
        data.merge!("api_token" => token)
      else
        data.merge!(EY.config.endpoint => {"api_token" => token})
      end

      File.open(file, "w"){|f| YAML.dump(data, f) }
      true
    end

  end # API
end # EY
