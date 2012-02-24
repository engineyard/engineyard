require 'rubygems'
require 'sinatra/base'
require 'json'
require 'hashie'
require 'gitable'
require 'ey_resolver'
require File.expand_path('../scenarios', __FILE__)
require File.expand_path('../models', __FILE__)

class FakeAwsm < Sinatra::Base
  disable :show_exceptions
  enable :raise_errors

  SCENARIOS = {
    "empty"                                               => Scenario::Base.new,
    "one app, one environment, not linked"                => Scenario::UnlinkedApp.new,
    "two apps"                                            => Scenario::TwoApps.new,
    "one app, one environment"                            => Scenario::LinkedApp.new,
    "two accounts, two apps, two environments, ambiguous" => Scenario::MultipleAmbiguousAccounts.new,
    "one app, one environment, no instances"              => Scenario::LinkedAppNotRunning.new,
    "one app, one environment, app master red"            => Scenario::LinkedAppRedMaster.new,
    "one app, many environments"                          => Scenario::OneAppManyEnvs.new,
    "one app, many similarly-named environments"          => Scenario::OneAppManySimilarlyNamedEnvs.new,
    "two apps, same git uri"                              => Scenario::TwoAppsSameGitUri.new,
  }

  def initialize(*_)
    super
    # the class var is because the object passed to #run is #dup-ed on
    # every request. It makes sense; you hardly ever want to keep
    # state in your application object (accidentally or otherwise),
    # but in this situation that's exactly what we want to do.
    @user = Scenario::Base.new.user
  end

  before do
    content_type "application/json"
    token = request.env['HTTP_X_EY_CLOUD_TOKEN']
    if token
      @user = User.first(:api_token => token)
    end
  end

  get "/" do
    content_type :html
    "OMG"
  end

  get "/scenario" do
    new_scenario = SCENARIOS[params[:scenario]]
    unless new_scenario
      status(404)
      return {"ok" => "false", "message" => "wtf is the #{params[:scenario]} scenario?"}.to_json
    end
    user = new_scenario.user
    {
      "scenario" => {
        "email"     => user.email,
        "password"  => user.password,
        "api_token" => user.api_token,
      }
    }.to_json
  end

  get "/api/v2/current_user" do
    { "user" => @user.to_api_response }.to_json
  end

  get "/api/v2/apps" do
    raise('No user agent header') unless env['HTTP_USER_AGENT'] =~ %r#^EngineYardCloudClient/#
    apps = @user.accounts.apps.map { |app| app.to_api_response }
    {"apps" => apps}.to_json
  end

  get "/api/v2/environments" do
    environments = @user.accounts.environments.map { |env| env.to_api_response }
    {"environments" => environments}.to_json
  end

  get "/api/v2/environments/resolve" do
    resolver = EY::Resolver.environment_resolver(@user, params['constraints'])
    envs = resolver.matches
    if envs.any?
      {
        'environments' => envs.map {|env| env.to_api_response},
        'errors' => [],
        'suggestions' => {}
      }.to_json
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
      }.to_json
    end
  end

  get "/api/v2/app_environments/resolve" do
    resolver = EY::Resolver.app_env_resolver(@user, params['constraints'])
    app_envs = resolver.matches
    if app_envs.any?
      {
        'app_environments' => app_envs.map {|app_env| app_env.to_api_response},
        'errors' => [],
        'suggestions' => {}
      }.to_json
    else
      errors = resolver.errors
      if resolver.suggestions
        api_suggest = resolver.suggestions.inject({}) do |suggest, k,v|
          if v
            suggest.merge(k => v.map { |obj| obj.to_api_response })
          else
            suggest
          end
        end
      end
      {
        'app_environments' => [],
        'errors'           => errors,
        'suggestions'      => api_suggest,
      }.to_json
    end
  end

  get "/api/v2/environments/:env_id/logs" do
    {
      "logs" => [
        {
          "id" => params['env_id'].to_i,
          "role" => "app_master",
          "main" => "MAIN LOG OUTPUT",
          "custom" => "CUSTOM LOG OUTPUT"
        }
      ]
    }.to_json
  end

  get "/api/v2/environments/:env_id/recipes" do
    redirect '/fakes3/recipe'
  end

  get "/fakes3/recipe" do
    content_type "binary/octet-stream"
    status(200)

    tempdir = File.join(Dir.tmpdir, "ey_test_cmds_#{Time.now.tv_sec}#{Time.now.tv_usec}_#{$$}")
    Dir.mkdir(tempdir)
    Dir.mkdir("#{tempdir}/cookbooks")
    File.open("#{tempdir}/cookbooks/README", 'w') do |f|
      f.write "Remove this file to clone an upstream git repository of cookbooks\n"
    end

    Dir.chdir(tempdir) { `tar czf - cookbooks` }
  end

  post "/api/v2/environments/:env_id/recipes" do
    if params[:file][:tempfile]
      files = `tar --list -z -f "#{params[:file][:tempfile].path}"`.split(/\n/)
      if files.empty?
        status(400)
        "No files in uploaded tarball"
      else
        status(204)
        ""
      end
    else
      status(400)
      "Recipe file not uploaded"
    end
  end

  put "/api/v2/environments/:env_id/update_instances" do
    status(202)
    ""
  end

  put "/api/v2/environments/:env_id/run_custom_recipes" do
    status(202)
    ""
  end

  get "/api/v2/apps/:app_id/environments/:environment_id/deployments/last" do
    {
      "deployment" => {
        "id" => 3,
        "ref" => "HEAD",
        "resolved_ref" => "HEAD",
        "commit" => 'a'*40,
        "user_name" => "User Name",
        "migrate_command" => "rake db:migrate --trace",
        "created_at" => Time.now.utc - 3600,
        "finished_at" => Time.now.utc - 3400,
        "successful" => true,
      }
    }.to_json
  end

  post "/api/v2/apps/:app_id/environments/:environment_id/deployments" do
    {"deployment" => params[:deployment].merge({"id" => 2, "commit" => 'a'*40, "resolved_ref" => "resolved-#{params[:deployment][:ref]}"})}.to_json
  end

  put "/api/v2/apps/:app_id/environments/:environment_id/deployments/:deployment_id/finished" do
    {"deployment" => params[:deployment].merge({"id" => 2, "finished_at" => Time.now})}.to_json
  end

  post "/api/v2/authenticate" do
    user = User.first(:email => params[:email], :password => params[:password])
    if user
      {"api_token" => user.api_token, "ok" => true}.to_json
    else
      status(401)
      {"ok" => false}.to_json
    end
  end

end

run FakeAwsm.new
