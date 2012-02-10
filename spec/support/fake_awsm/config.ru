require 'rubygems'
require 'sinatra/base'
require 'json'
require 'hashie'
require 'gitable'
require 'ey_resolver'
require File.expand_path('../scenarios', __FILE__)
require File.expand_path('../cloud_mock', __FILE__)
require File.expand_path('../models', __FILE__)

class FakeAwsm < Sinatra::Base
  disable :show_exceptions
  enable :raise_errors

  SCENARIOS = {
    "empty"                                               => CloudMock.new(Scenario::Base.new),
    "one app, one environment, not linked"                => CloudMock.new(Scenario::UnlinkedApp.new),
    "two apps"                                            => CloudMock.new(Scenario::TwoApps.new),
    "one app, one environment"                            => CloudMock.new(Scenario::LinkedApp.new),
    "two accounts, two apps, two environments, ambiguous" => CloudMock.new(Scenario::MultipleAmbiguousAccounts.new),
    "one app, one environment, no instances"              => CloudMock.new(Scenario::LinkedAppNotRunning.new),
    "one app, one environment, app master red"            => CloudMock.new(Scenario::LinkedAppRedMaster.new),
    "one app, many environments"                          => CloudMock.new(Scenario::OneAppManyEnvs.new),
    "one app, many similarly-named environments"          => CloudMock.new(Scenario::OneAppManySimilarlyNamedEnvs.new),
    "two apps, same git uri"                              => CloudMock.new(Scenario::TwoAppsSameGitUri.new),
  }

  def initialize(*_)
    super
    # the class var is because the object passed to #run is #dup-ed on
    # every request. It makes sense; you hardly ever want to keep
    # state in your application object (accidentally or otherwise),
    # but in this situation that's exactly what we want to do.
    @@cloud_mock = CloudMock.new(Scenario::Base.new('git://example.com'))
  end

  before { content_type "application/json" }

  get "/" do
    content_type :html
    "OMG"
  end

  put "/scenario" do
    new_scenario = SCENARIOS[params[:scenario]]
    unless new_scenario
      status(400)
      return {"ok" => "false", "message" => "wtf is the #{params[:scenario]} scenario?"}.to_json
    end
    @@cloud_mock = new_scenario
    {"ok" => "true"}.to_json
  end

  get "/api/v2/current_user" do
    { "user" => { "id" => 1, "name" => "User Name", "email" => "test@test.test" } }.to_json
  end

  get "/api/v2/apps" do
    raise('No user agent header') unless env['HTTP_USER_AGENT'] =~ %r#^EngineYardCloudClient/#
    {"apps" => @@cloud_mock.apps}.to_json
  end

  get "/api/v2/environments" do
    {"environments" => @@cloud_mock.environments}.to_json
  end

  get "/api/v2/environments/resolve" do
    @@cloud_mock.resolve_environments(params['constraints']).to_json
  end

  get "/api/v2/app_environments/resolve" do
    @@cloud_mock.resolve_app_environments(params['constraints']).to_json
  end

  get "/api/v2/environments/:env_id/logs" do
    {"logs" => @@cloud_mock.logs(params[:env_id].to_i)}.to_json
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
    if valid_user?
      {"api_token" => "deadbeef", "ok" => true}.to_json
    else
      status(401)
      {"ok" => false}.to_json
    end
  end

private

  def valid_user?
    params[:email] == "test@test.test" &&
      params[:password] == "test"
  end

end

run FakeAwsm.new
