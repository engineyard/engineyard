module EY
  class API
    class InvalidCredentials < StandardError; end

    def self.default_endpoint
      "https://cloud.engineyard.com"
    end

    attr_reader :endpoint

    def initialize(endpoint)
      @endpoint = (endpoint || self.class.default_endpoint)
    end

    def default_endpoint?
      endpoint == self.class.default_endpoint
    end

    def request(path, opts={})
      EY.library 'rest_client'
      EY.library 'json'

      url = endpoint.chomp('/') + "/api/v2" + path
      method = ((meth = opts.delete(:method)) && meth.to_s || "get").downcase.to_sym
      params = opts.delete(:params) || {}
      headers = opts.delete(:headers) || {}
      headers["Accept"] ||= "application/json"

      begin
        case method
        when :get
          url += "?#{RestClient::Payload::UrlEncoded.new(params)}"
          resp = RestClient.get(url, headers)
        else
          resp = RestClient.send(method, url, params, headers)
        end
      rescue RestClient::Unauthorized
        raise InvalidCredentials
      rescue Errno::ECONNREFUSED
        puts "Could not reach the cloud API"
        raise EY::CLI::Exit
      rescue RestClient::ResourceNotFound
        puts "The requested resource could not be found"
        raise EY::CLI::Exit
      rescue RestClient::RequestFailed => e
        puts "Request failed: #{e.message}"
        raise EY::CLI::Exit
      end

      JSON.parse(resp) if resp
    end

  end
end