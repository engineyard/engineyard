module EY
  class Token
    class InvalidCredentials < StandardError; end
    
    attr_reader :token
    
    def initialize(token)
      @token = token
    end
    
    def request(url, opts={})
      opts[:headers] ||= {}
      opts[:headers]["X-EY-Cloud-Token"] = token
      EY::Request.request(url, opts)
    end
    
    def self.from_file(file = File.expand_path("~/.eyrc"))
      if File.exists?(file)
        new(YAML.load_file(file)["api_token"])
      else
        false
      end
    end
    
    def self.fetch(email, password, file = File.expand_path("~/.eyrc"))
      response = EY::Request.request("/authenticate", 
                                     :method => "post",
                                     :params => {
                                       :email    => email, 
                                       :password => password
                                     })
                                  
      token = response["api_token"]
      if file && !File.exists?(file)
        File.open(file, "w") do |fp|
          fp.write YAML.dump({"api_token" => token})
        end
      end
      new(token)
    rescue RestClient::Unauthorized
      raise InvalidCredentials
    end
  end
end
