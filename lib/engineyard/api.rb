require 'engineyard/model'

module EY
  class API
    attr_reader :token

    def initialize(token = nil)
      @token ||= token
      @token ||= self.class.read_token
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

    def environments
      @environments ||= EY::Model::Environment.from_array(request('/environments')["environments"], :api => self)
    end

    def apps
      @apps ||= EY::Model::App.from_array(request('/apps')["apps"], :api => self)
    end

    def environment_named(name, envs = self.environments)
      envs.find{|e| e.name == name }
    end

    def app_for_repo(repo)
      apps.find{|a| repo.urls.include?(a.repository_uri) }
    end

    class InvalidCredentials < EY::Error; end
    class RequestFailed < EY::Error; end


    def self.request(path, opts={})
      require 'rest_client'
      require 'json'

      url = EY.config.endpoint + "api/v2#{path}"
      method = ((meth = opts.delete(:method)) && meth.to_s || "get").downcase.to_sym
      params = opts.delete(:params) || {}
      headers = opts.delete(:headers) || {}
      headers["Accept"] ||= "application/json"

      begin
        EY.ui.debug("Request", "#{method.to_s.upcase} #{url}")
        case method
        when :get, :delete, :head
          url.query = RestClient::Payload::UrlEncoded.new(params).to_s
          resp = RestClient.send(method, url.to_s, headers)
        else
          resp = RestClient.send(method, url.to_s, params, headers)
        end
      rescue RestClient::Unauthorized
        raise InvalidCredentials
      rescue Errno::ECONNREFUSED
        raise RequestFailed, "Could not reach the cloud API"
      rescue RestClient::ResourceNotFound
        raise RequestFailed, "The requested resource could not be found"
      rescue RestClient::RequestFailed => e
        raise RequestFailed, "#{e.message}"
      rescue OpenSSL::SSL::SSLError
        raise RequestFailed, "SSL is misconfigured on your cloud"
      end

      if resp.code == 204
        data = nil
      else
        begin
          data = JSON.parse(resp.body)
          EY.ui.debug("Response", data)
        rescue JSON::ParserError
          EY.ui.debug("Raw response", resp.body)
          raise RequestFailed, "Response was not valid JSON."
        end
      end

      data
    end

    def self.fetch_token(email, password)
      api_token = request("/authenticate", :method => "post",
        :params => { :email => email, :password => password })["api_token"]
      save_token(api_token)
      api_token
    end

    def self.read_token(file = nil)
      file ||= ENV['EYRC'] || File.expand_path("~/.eyrc")
      return false unless File.exists?(file)

      require 'yaml'

      data = YAML.load_file(file)
      if EY.config.default_endpoint?
        data["api_token"]
      else
        (data[EY.config.endpoint.to_s] || {})["api_token"]
      end
    end

    def self.save_token(token, file = nil)
      file ||= ENV['EYRC'] || File.expand_path("~/.eyrc")
      require 'yaml'

      data = File.exists?(file) ? YAML.load_file(file) : {}
      if EY.config.default_endpoint?
        data.merge!("api_token" => token)
      else
        data.merge!(EY.config.endpoint.to_s => {"api_token" => token})
      end

      File.open(file, "w"){|f| YAML.dump(data, f) }
      true
    end

  end # API
end # EY
