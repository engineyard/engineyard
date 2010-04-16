require 'engineyard/account/app'
require 'engineyard/account/app_master'
require 'engineyard/account/environment'
require 'engineyard/account/log'

module EY
  class Account

    def initialize(api)
      @api = api
    end

    def request(path, options = { })
      @api.request(path, {:method => :get}.merge(options))
    end

    def environments
      return @environments if @environments
      data = request('/environments')["environments"]
      @environments = Environment.from_array(data || [], self)
    end

    def environment_named(name)
      environments.find{|e| e.name == name }
    end

    def apps
      return @apps if @apps
      data  = @api.request('/apps')["apps"]
      @apps = App.from_array(data || [], self)
    end

    def app_named(name)
      apps.find{|a| a.name == name }
    end

    def app_for_repo(repo)
      apps.find{|a| repo.urls.include?(a.repository_url) }
    end

  end # Account
end # EY
