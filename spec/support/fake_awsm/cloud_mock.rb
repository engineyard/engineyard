require File.expand_path('../models', __FILE__)

class CloudMock
  attr_reader :user

  def initialize(scenario)
    @scenario = scenario
    @user = @scenario.user
  end

  def apps
    @user.accounts.apps.map { |app| app.to_api_response }
  end

  def logs(env_id)
    [{
      "id" => env_id,
      "role" => "app_master",
      "main" => "MAIN LOG OUTPUT",
      "custom" => "CUSTOM LOG OUTPUT"
    }]
  end

  def environments
    @user.accounts.environments.map { |env| env.to_api_response }
  end

  def resolve_environments(constraints)
    resolver = EY::Resolver.environment_resolver(@user, constraints)
    envs = resolver.matches
    if envs.any?
      {
        'environments' => envs.map {|env| env.to_api_response}
      }
    else
      errors = resolver.errors
      if resolver.suggestions
        api_suggest = resolver.suggestions.inject({}) do |suggest, k,v|
          suggest.merge(k => v.map { |obj| obj.to_api_response })
        end
      end
      {
        'environments' => [],
        'errors'       => errors,
        'suggestions'  => api_suggest,
      }
    end
  end

  def resolve_app_environments(constraints)
    resolver = EY::Resolver.app_env_resolver(@user, constraints)
    app_envs = resolver.matches
    if app_envs.any?
      {
        'app_environments' => app_envs.map {|app_env| app_env.to_api_response}
      }
    else
      errors = resolver.errors
      if resolver.suggestions
        api_suggest = resolver.suggestions.inject({}) do |suggest, k,v|
          if v
            suggest.merge(k => v.map { |obj| obj.to_api_response })
          end
        end
      end
      {
        'app_environments' => [],
        'errors'           => errors,
        'suggestions'      => api_suggest,
      }
    end
  end
end
