require 'engineyard-api-client/ruby_ext'
require 'engineyard-api-client/models'
require 'engineyard-api-client/collections'
require 'engineyard-api-client/rest_client_ext'
require 'engineyard-api-client/resolver'
require 'engineyard-api-client/version'
require 'json'
require 'engineyard/eyrc'

module EY
  class APIClient
    attr_reader :token

    USER_AGENT_STRING = "EngineYardAPIClient/#{EY::APIClient::VERSION}"

    def initialize(token = nil)
      @token = token
      @token ||= EY::EYRC.load.api_token
      raise ArgumentError, "EY Cloud API token required" unless @token
    end

    def request(url, opts={})
      opts[:headers] ||= {}
      opts[:headers]["X-EY-Cloud-Token"] = token
      EY.ui.debug("Token", token)
      self.class.request(url, opts)
    end

    def fetch_environment(environment_name, account_name=nil, repo=nil)
      options = {
        :environment_name => environment_name,
        :account_name => account_name,
        :repo => repo,
      }
      resolver.environment(options)
    end

    def fetch_app_and_environment(app_name=nil, environment_name=nil, account_name=nil, repo=nil)
      options = {
        :app_name => app_name,
        :environment_name => environment_name,
        :account_name => account_name,
        :repo => repo,
      }
      resolver.app_and_environment(options)
    end

    # TODO: unhaxor
    # This should load an api endpoint that deals directly in app_deployments
    def fetch_app_environment(app_name = nil, environment_name = nil, account_name = nil, repo=nil)
      app, env = fetch_app_and_environment(app_name, environment_name, account_name)
      env.app_environment_for(app)
    end

    def environments
      @environments ||= EY::APIClient::Environment.from_array(request('/environments')["environments"], :api => self)
    end

    def apps
      @apps ||= EY::APIClient::App.from_array(request('/apps')["apps"], :api => self)
    end

    def resolver
      @resolver ||= EY::APIClient::Resolver.new(self)
    end

    def current_user
      EY::APIClient::User.from_hash(request('/current_user')['user'])
    end

    class InvalidCredentials < EY::Error; end
    class RequestFailed < EY::Error; end
    class ResourceNotFound < RequestFailed; end

    def self.request(path, opts={})
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
        raise RequestFailed, "EY Cloud API is temporarily unavailable. Please try again soon."
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
