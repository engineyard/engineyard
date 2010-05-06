require 'engineyard/account/api_struct'
require 'engineyard/account/app'
require 'engineyard/account/app_master'
require 'engineyard/account/environment'
require 'engineyard/account/log'
require 'engineyard/account/instance'

module EY
  class Account

    def initialize(api)
      @api = api
    end

    def environments
      @environments ||= begin
        data = @api.request('/environments')["environments"]
        Environment.from_array(data, self)
      end
    end

    def apps
      @apps ||= App.from_array(@api.request('/apps')["apps"], self)
    end

    def environment_named(name)
      environments.find{|e| e.name == name }
    end

    def logs_for(env)
      data = @api.request("/environments/#{env.id}/logs")["logs"]
      Log.from_array(data)
    end

    def instances_for(env)
      @instances ||= begin
        data = @api.request("/environments/#{env.id}/instances")["instances"]
        Instance.from_array(data)
      end
    end

    def upload_recipes_for(env)
      @api.request("/environments/#{env.id}/recipes",
        :method => :post,
        :params => {:file => env.recipe_file}
      )
    end

    def rebuild(env)
      @api.request("/environments/#{env.id}/rebuild",
        :method => :put)
    end

    def app_named(name)
      apps.find{|a| a.name == name }
    end

    def app_for_repo(repo)
      apps.find{|a| repo.urls.include?(a.repository_uri) }
    end

  end # Account
end # EY
