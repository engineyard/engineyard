module EY
  class API
    class InvalidCredentials < EY::Error; end
    class RequestFailed < EY::Error; end

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
        EY.ui.debug("Request", method.to_s.upcase + " " + url)
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
        raise EY::Error, "Could not reach the cloud API"
      rescue RestClient::ResourceNotFound
        raise EY::Error, "The requested resource could not be found"
      rescue RestClient::RequestFailed => e
        raise RequestFailed, "#{e.message}"
      end

      begin
        resp = JSON.parse(resp) if resp
        EY.ui.debug("Response", resp.inspect)
      rescue JSON::ParserError
        raise RequestFailed, "Response was not valid JSON."
      end

      resp
    end

  end
end