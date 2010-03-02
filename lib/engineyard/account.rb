module EY
  class Account
    def initialize(api)
      @api = api
    end

    def environments
      @environments ||= @api.request('/environments', :method => :get)["environments"] || {}
    end

    def apps
      @apps ||= @api.request('/apps', :method => :get)["apps"] || {}
    end

    def app_for_url(url)
      apps.find{|a| a["repository_uri"] == url }
    end

  end # Account
end # EY
