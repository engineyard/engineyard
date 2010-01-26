require 'rest_client'
require 'json'

module EY
  module Request
    def self.api_endpoint
      ENV["CLOUD_URL"] || "https://cloud.engineyard.com"
    end

    def self.request(path, opts={})
      url = api_endpoint.chomp('/') + "/api/v2" + path
      method = ((meth = opts.delete(:method)) && meth.to_s || "post").downcase.to_sym
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
      rescue RestClient::RequestFailed => e
        $stderr.puts "Request failed: #{e.message}"
      end

      JSON.parse(resp) if resp
    end
  end
end
