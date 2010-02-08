module EY
  module Request
    class InvalidCredentials < StandardError; end

    def self.api_endpoint
      ENV["CLOUD_URL"] || "https://cloud.engineyard.com"
    end

    def self.request(path, opts={})
      EY.library 'rest_client'
      EY.library 'json'

      url = api_endpoint.chomp('/') + "/api/v2" + path
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
      rescue RestClient::ResourceNotFound
        puts "Could not reach the cloud API."
        raise EY::CLI::Exit
      rescue RestClient::RequestFailed => e
        puts "Request failed: #{e.message}"
        raise EY::CLI::Exit
      end

      JSON.parse(resp) if resp
    end
  end
end
