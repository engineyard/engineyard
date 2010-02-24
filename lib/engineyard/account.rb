module EY
  class Account
    def initialize(token)
      @token = token
    end

    def environments
      @environments ||= @token.request('/environments', :method => :get)["environments"] || {}
    end

    def apps
      @apps ||= @token.request('/apps', :method => :get)["apps"] || {}
    end

    def app_for_url(url)
      apps.find{|a| a["repository_uri"] == url }
    end

  end # Account
end # EY
