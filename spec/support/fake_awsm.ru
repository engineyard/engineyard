require 'rubygems'
require 'sinatra/base'
require 'json'
require File.expand_path('../scenarios', __FILE__)

class FakeAwsm < Sinatra::Base
  SCENARIOS = {
    "empty"                                               => Scenario::Base,
    "one app, one environment, not linked"                => Scenario::UnlinkedApp,
    "two apps"                                            => Scenario::TwoApps,
    "one app, one environment"                            => Scenario::LinkedApp,
    "two accounts, two apps, two environments, ambiguous" => Scenario::MultipleAmbiguousAccounts,
    "one app, one environment, no instances"              => Scenario::LinkedAppNotRunning,
    "one app, one environment, app master red"            => Scenario::LinkedAppRedMaster,
    "one app, many environments"                          => Scenario::OneAppManyEnvs,
    "one app, many similarly-named environments"          => Scenario::OneAppManySimilarlyNamedEnvs,
    "two apps, same git uri"                              => Scenario::TwoAppsSameGitUri,
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
    @@cloud_mock = CloudMock.new(new_scenario.new(params[:remote]))
    {"ok" => "true"}.to_json
  end

  get "/api/v2/apps" do
    raise('No user agent header') unless env['HTTP_USER_AGENT'] =~ %r#^EngineYardCLI/#
    {"apps" => @@cloud_mock.apps}.to_json
  end

  get "/api/v2/environments" do
    {"environments" => @@cloud_mock.environments}.to_json
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
        "user_name" => "User",
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

  class CloudMock
    def initialize(initial_conditions)
      @accounts, @apps, @envs, @keys, @app_joins, @key_joins = [], [], [], [], [], []
      @next_id = 1

      initial_conditions.starting_accounts.each     {|a| add_account(a) }
      initial_conditions.starting_apps.each         {|a| add_app(a) }
      initial_conditions.starting_environments.each {|e| add_environment(e) }
      initial_conditions.starting_app_joins.each    {|(app_id, env_id)| link_app(app_id, env_id) }
    end

    def add_account(acc)
      acc["id"] ||= next_id
      @accounts << acc
      acc
    end

    def add_app(app)
      app["id"] ||= next_id
      app["account"] ||= @accounts.first
      @apps << app
      app
    end

    def add_environment(env)
      env["id"] ||= next_id
      env["account"] ||= @accounts.first

      unless env.has_key?("app_master")
        master = env["instances"].find{ |i| %w[solo app_master].include?(i["role"]) }
        env.merge!("app_master" => master)
      end

      @envs << env
      env
    end

    def link_app(app_id, env_id)
      app = @apps.find {|a| a["id"] == app_id } or raise "No such app id:#{app_id}"
      env = @envs.find {|e| e["id"] == env_id } or raise "No such environment id:#{env_id}"
      if app["account"]["id"] != env["account"]["id"]
        raise "App #{app_id} in account #{app["account"]["id"]} cannot be attached to environment #{env_id} in account #{env["account"]["id"]}"
      end
      @app_joins << [app_id, env_id]
      @app_joins.uniq!
    end

    def apps
      @apps.dup.map do |app|
        app.merge("environments" => joined_envs(app))
      end
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
      @envs.dup.map do |env|
        env.merge("apps" => joined_apps(env))
      end
    end

    private

    def next_id
      id = @next_id
      @next_id += 1
      id
    end

    def joined_envs(app)
      related_objects(app, @envs, @app_joins)
    end

    def joined_apps(env)
      related_objects(env, @apps, @app_joins.map {|j| j.reverse})
    end

    def related_objects(obj, candidates, relation)
      candidate_table = candidates.inject({}) do |table, candidate|
        table.merge(candidate["id"] => candidate)
      end

      relation.find_all do |(obj_id, candidate_id)|
        obj["id"] == obj_id
      end.map do |(obj_id, candidate_id)|
        candidate_table[candidate_id]
      end
    end
  end
end

run FakeAwsm.new
