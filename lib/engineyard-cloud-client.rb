module EY
  class CloudClient
  end
end

require 'engineyard-cloud-client/ruby_ext'
require 'engineyard-cloud-client/models'
require 'engineyard-cloud-client/collections'
require 'engineyard-cloud-client/rest_client_ext'
require 'engineyard-cloud-client/resolver'
require 'engineyard-cloud-client/version'
require 'engineyard-cloud-client/errors'
require 'json'
require 'pp'

module EY
  class CloudClient
    attr_reader :token

    USER_AGENT_STRING = "EngineYardCloudClient/#{EY::CloudClient::VERSION}"

    def self.endpoint
      @endpoint
    end

    def self.endpoint=(endpoint)
      @endpoint = URI.parse(endpoint)
      unless @endpoint.absolute?
        raise BadEndpointError.new(endpoint)
      end
      @endpoint
    end

    def self.default_endpoint!
      self.endpoint = "https://cloud.engineyard.com/"
    end
    default_endpoint!

    def initialize(token)
      self.token = token
    end

    def token=(new_token)
      unless new_token
        raise ArgumentError, "EY Cloud API token required"
      end
      @token = new_token
    end

    def request(url, opts={})
      opts[:headers] ||= {}
      opts[:headers]["X-EY-Cloud-Token"] = token
      EY.ui.debug("Token", token)
      self.class.request(url, opts)
    end

    def fetch_environment(environment_name, account_name, repo)
      Resolver.new(self, {
        :environment_name => environment_name,
        :account_name     => account_name,
        :repo             => repo,
      }).environment
    end

    def fetch_app_environment(app_name, environment_name, account_name, repo)
      Resolver.new(self, {
        :app_name         => app_name,
        :environment_name => environment_name,
        :account_name     => account_name,
        :repo             => repo,
      }).app_environment
    end

    def environments
      @environments ||= EY::CloudClient::Environment.all(self)
    end

    def apps
      @apps ||= EY::CloudClient::App.all(self)
    end

    # TODO: unhaxor
    # This should load an api endpoint that deals directly in app_deployments
    def app_environments
      @app_environments ||= apps.map { |app| app.app_environments }.flatten
    end

    def current_user
      EY::CloudClient::User.from_hash(self, request('/current_user')['user'])
    end

    def self.request(path, opts={})
      url = self.endpoint + "api/v2#{path}"
      method = (opts.delete(:method) || 'get').to_s.downcase.to_sym
      params = opts.delete(:params) || {}
      headers = opts.delete(:headers) || {}
      headers["Accept"] ||= "application/json"
      headers["User-Agent"] = USER_AGENT_STRING

      begin
        EY.ui.debug("Request", "#{method.to_s.upcase} #{url}")
        EY.ui.debug("Params", params.inspect)
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
          EY.ui.debug("Response", "\n" + data.pretty_inspect)
        rescue JSON::ParserError
          EY.ui.debug("Raw response", resp.body)
          raise RequestFailed, "Response was not valid JSON."
        end
      else
        data = resp.body
      end

      data
    end

    def self.authenticate(email, password)
      request("/authenticate", :method => "post", :params => { :email => email, :password => password })["api_token"]
    end

  end # API
end # EY
