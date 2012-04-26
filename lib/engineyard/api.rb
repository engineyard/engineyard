require 'engineyard/model'
require 'yaml'
require 'rest_client'
require 'engineyard/rest_client_ext'
require 'json'
require 'engineyard/eyrc'

module EY
  class API
    attr_reader :token

    USER_AGENT_STRING = "EngineYardCLI/#{VERSION}"

    def initialize(token = nil)
      @token = token
      @token ||= EY::EYRC.load.api_token
      raise ArgumentError, "Engine Yard Cloud API token required" unless @token
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

    def resolver
      @resolver ||= Resolver.new(self)
    end

    def apps_for_repo(repo)
      repo.fail_on_no_remotes!
      apps.find_all {|a| repo.has_remote?(a.repository_uri) }
    end

    def user
      EY::Model::User.from_hash(request('/current_user')['user'])
    end

    class InvalidCredentials < EY::Error; end
    class RequestFailed < EY::Error; end
    class ResourceNotFound < RequestFailed; end

    def self.request(path, opts={})
      require 'rest_client'
      require 'engineyard/rest_client_ext'
      require 'json'

      url = EY.config.endpoint + "api/v2#{path}"
      method = (opts.delete(:method) || 'get').to_s.downcase.to_sym
      params = opts.delete(:params) || {}
      headers = opts.delete(:headers) || {}
      headers["Accept"] ||= "application/json"
      headers["User-Agent"] = USER_AGENT_STRING

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
        raise ResourceNotFound, "The requested resource could not be found"
      rescue RestClient::BadGateway
        raise RequestFailed, "Engine Yard Cloud API is temporarily unavailable. Please try again soon."
      rescue RestClient::RequestFailed => e
        raise RequestFailed, "#{e.message} #{e.response}"
      rescue OpenSSL::SSL::SSLError
        raise RequestFailed, "SSL is misconfigured on your cloud"
      end

      if resp.body.empty?
        data = ''
      elsif resp.headers[:content_type] =~ /application\/json/
        begin
          data = JSON.parse(resp.body)
          EY.ui.debug("Response", data)
        rescue JSON::ParserError
          EY.ui.debug("Raw response", resp.body)
          raise RequestFailed, "Response was not valid JSON."
        end
      else
        data = resp.body
      end

      data
    end

    def self.fetch_token(email, password)
      api_token = request("/authenticate", :method => "post",
        :params => { :email => email, :password => password })["api_token"]
      EY::EYRC.load.api_token = api_token
      api_token
    end

  end # API
end # EY
