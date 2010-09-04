require 'rubygems'
require 'sinatra/base'
require 'json'

class FakeAwsm < Sinatra::Base

  def initialize(*_)
    super
    # the class var is because the object passed to #run is #dup-ed on
    # every request. It makes sense; you hardly ever want to keep
    # state in your application object (accidentally or otherwise),
    # but in this situation that's exactly what we want to do.
    @@cloud_mock = Scenario::Base  # have to start somewhere
  end

  before { content_type "application/json" }

  get "/" do
    content_type :html
    "OMG"
  end

  put "/scenario" do
    new_scenario = case params[:scenario]
                   when "empty"
                     Scenario::Base
                   when "one app, one environment, not linked"
                     Scenario::UnlinkedApp
                   when "two apps"
                     Scenario::TwoApps
                   when "one app, one environment"
                     Scenario::LinkedApp
                   when "two accounts, two apps, two environments, ambiguous"
                     Scenario::MultipleAmbiguousAccounts
                   when "one app, one environment, no instances"
                     Scenario::LinkedAppNotRunning
                   when "one app, one environment, app master red"
                     Scenario::LinkedAppRedMaster
                   when "one app, many environments"
                     Scenario::OneAppManyEnvs
                   when "one app, many similarly-named environments"
                     Scenario::OneAppManySimilarlyNamedEnvs
                   when "two apps, same git uri"
                     Scenario::TwoAppsSameGitUri
                   else
                     status(400)
                     return {"ok" => "false", "message" => "wtf is the #{params[:scenario]} scenario?"}.to_json
                   end
    @@cloud_mock = CloudMock.new(new_scenario.new(params[:remote]))
    {"ok" => "true"}.to_json
  end

  get "/api/v2/apps" do
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

  put "/api/v2/environments/:env_id/rebuild" do
    status(202)
    ""
  end

  put "/api/v2/environments/:env_id/run_custom_recipes" do
    status(202)
    ""
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

  module Scenario
    class Base
      attr_accessor :git_remote

      def initialize(git_remote)
        self.git_remote = git_remote
      end

      def starting_accounts()     [{"name" => "main"}] end
      def starting_apps()         [] end
      def starting_environments() [] end
      def starting_app_joins()    [] end

    end

    class LinkedApp < Base
      def _instances
        [{
            "id" => 27220,
            "role" => "app_master",
            "name" => nil,
            "status" => "running",
            "amazon_id" => 'i-ddbbdd92',
            "public_hostname" => "app_master_hostname.compute-1.amazonaws.com",
          }, {
            "id" => 22721,
            "name" => nil,
            "role" => "db_master",
            "status" => "running",
            "amazon_id" => "i-d4cdddbf",
            "public_hostname" => "db_master_hostname.compute-1.amazonaws.com",
          }, {
            "id" => 22724,
            "name" => nil,
            "role" => "db_slave",
            "status" => "running",
            "amazon_id" => "i-asdfasdfaj",
            "public_hostname" => "db_slave_1_hostname.compute-1.amazonaws.com",
          }, {
            "id" => 22725,
            "name" => nil,
            "role" => "db_slave",
            "status" => "running",
            "amazon_id" => "i-asdfasdfaj",
            "public_hostname" => "db_slave_2_hostname.compute-1.amazonaws.com",
          }, {
            "id" => 22722,
            "role" => "app",
            "name" => nil,
            "status" => "building",
            "amazon_id" => "i-d2e3f1b9",
            "public_hostname" => "app_hostname.compute-1.amazonaws.com",
          }, {
            "id" => 22723,
            "role" => "util",
            "name" => "fluffy",
            "status" => "running",
            "amazon_id" => "i-80e3f1eb",
            "public_hostname" => "util_fluffy_hostname.compute-1.amazonaws.com",
          }, {
            "id" => 22727,
            "role" => "util",
            "name" => "rocky",
            "status" => "running",
            "amazon_id" => "i-80etf1eb",
            "public_hostname" => "util_rocky_hostname.compute-1.amazonaws.com",
          }]
      end
      private :_instances

      def starting_apps
        [{
            "id" => 1001,
            "name" => "rails232app",
            "repository_uri" => git_remote}]
      end

      def starting_environments
        [{
            "id" => 200,
            "ssh_username" => "turkey",
            "instances" => _instances,
            "name" => "giblets",
            "instances_count" => 4,
            "stack_name" => "nginx_mongrel",
            "framework_env" => "production"}]
      end

      def starting_app_joins
        [[1001, 200]]
      end

    end  # LinkedApp

    class MultipleAmbiguousAccounts < LinkedApp
      def starting_accounts
        super + [{"name" => "account_2", "id" => 256}]
      end

      def starting_apps
        apps = super
        new_app = apps.first.dup
        new_app["id"] += 1000
        new_app["account"] = starting_accounts.last
        apps + [new_app]
      end

      def starting_environments
        envs = super
        new_env = envs.first.dup
        new_env["id"] += 1000
        new_env["account"] = starting_accounts.last
        envs + [new_env]
      end

      def starting_app_joins
        joins = super
        new_join = [joins.first[0] + 1000, 
                    joins.first[1] + 1000]
        joins + [new_join]
      end
    end

    class UnlinkedApp < Base
      def starting_apps
        [{
            "id" => 1001,
            "name" => "rails232app",
            "repository_uri" => git_remote}]
      end

      def starting_environments
        [{
            "ssh_username" => "turkey",
            "instances" => [{
                "status" => "running",
                "id" => 27220,
                "amazon_id" => 'i-ddbbdd92',
                "role" => "solo",
                "public_hostname" => "ec2-174-129-198-124.compute-1.amazonaws.com"}],
            "name" => "giblets",
            "instances_count" => 1,
            "stack_name" => "nginx_mongrel",
            "id" => 200,
            "framework_env" => "production"}]
      end
    end # UnlinkedApp

    class LinkedAppNotRunning < Base
      def starting_apps
        [{
            "id" => 1001,
            "name" => "rails232app",
            "repository_uri" => git_remote}]
      end

      def starting_environments
        [{
            "ssh_username" => "turkey",
            "instances" => [],
            "name" => "giblets",
            "instances_count" => 0,
            "stack_name" => "nginx_mongrel",
            "id" => 200,
            "framework_env" => "production"}]
      end

      def starting_app_joins
        [[1001, 200]]
      end
    end # LinkedAppNotRunning

    class LinkedAppRedMaster < LinkedApp
      def starting_environments
        envs = super
        envs[0]["instances"][0]["status"] = "error"
        envs
      end
    end

    class OneAppManyEnvs < Base
      def starting_apps
        [{
            "id" => 1001,
            "name" => "rails232app",
            "repository_uri" => git_remote}]
      end

      def starting_app_joins
        [
          [1001, 200],
          [1001, 202],
        ]
      end

      def starting_environments
        [{
            "ssh_username" => "turkey",
            "instances" => [{
                "status" => "running",
                "id" => 27220,
                "amazon_id" => 'i-ddbbdd92',
                "role" => "solo",
                "public_hostname" => "app_master_hostname.compute-1.amazonaws.com"}],
            "name" => "giblets",
            "instances_count" => 1,
            "stack_name" => "nginx_mongrel",
            "id" => 200,
            "framework_env" => "production",
          }, {
            "ssh_username" => "ham",
            "instances" => [],
            "name" => "bakon",
            "instances_count" => 0,
            "stack_name" => "nginx_passenger",
            "id" => 202,
          }, {
            "ssh_username" => "hamburger",
            "instances" => [],
            "name" => "beef",
            "instances_count" => 0,
            "stack_name" => "nginx_passenger",
            "id" => 206,
          }]
      end
    end # OneAppTwoEnvs

    class TwoApps < Base
      def railsapp_master
        {
          "status" => "running",
          "name" => nil,
          "role" => "solo",
          "public_hostname" => "ec2-174-129-7-113.compute-1.amazonaws.com",
          "id" => 35707,
          "amazon_id" => "i-0911f063",
        }
      end
      private :railsapp_master

      def keycollector_master
        {
          "status" => "running",
          "name" => nil,
          "role" => "solo",
          "public_hostname" => "app_master_hostname.compute-1.amazonaws.com",
          "id" => 75428,
          "amazon_id" => "i-051195b9",
        }
      end
      private :keycollector_master

      def starting_apps
        [{
            "id" => 3202,
            "name" => "keycollector",
            "repository_uri" => "git@github.com:smerritt/keycollector.git",
          }, {
            "id" => 6125,
            "name" => "rails232app",
            "repository_uri" => "git://github.com/smerritt/rails232app.git"}]
      end

      def starting_app_joins
        [
          [6125, 200],
          [3202, 439],
        ]
      end

      def starting_environments
        [{
            "id" => 200,
            "name" => "giblets",
            "framework_env" => "staging",
            "ssh_username" => "turkey",
            "instances_count" => 1,
            "instances" => [railsapp_master],
            "stack_name" => "nginx_unicorn",
          }, {
            "id" => 439,
            "framework_env" => "production",
            "name" => "keycollector_production",
            "ssh_username" => "deploy",
            "stack_name" => "nginx_mongrel",
            "instances_count" => 1,
            "instances" => [keycollector_master],
          }]
      end
    end # TwoApps

    class TwoAppsSameGitUri < TwoApps
      def starting_apps
        apps = super
        apps.each do |app|
          app["repository_uri"] = "git://github.com/engineyard/dup.git"
        end
        apps
      end
    end # TwoAppsSameGitUri

    class OneAppManySimilarlyNamedEnvs < Base
      def starting_apps
        [{
            "id" => 1001,
            "name" => "rails232app",
            "repository_uri" => git_remote}]
      end

      def starting_environments
        [{
            "id" => 200,
            "ssh_username" => "turkey",
            "instances" => [{
                "status" => "running",
                "id" => 27220,
                "amazon_id" => 'i-ddbbdd92',
                "role" => "solo",
                "public_hostname" => "app_master_hostname.compute-1.amazonaws.com"}],
            "name" => "railsapp_production",
            "instances_count" => 1,
            "stack_name" => "nginx_mongrel",
            "framework_env" => "production",
          }, {
            "id" => 202,
            "ssh_username" => "ham",
            "instances" => [{
                "public_hostname" => '127.3.2.1',
                "status" => "running",
                "id" => 63066,
                "role" => "solo",
              }],
            "name" => "railsapp_staging",
            "instances_count" => 1,
            "stack_name" => "nginx_passenger",
            "framework_env" => "production",
          }, {
            "ssh_username" => "ham",
            "instances" => [{
                "status" => "running",
                "id" => 59395,
                "role" => "solo",
                "public_hostname" => "ec2-174-129-198-124.compute-1.amazonaws.com",
              }],
            "name" => "railsapp_staging_2",
            "instances_count" => 1,
            "stack_name" => "nginx_passenger",
            "id" => 204,
            "framework_env" => "production",
          }]
      end

      def starting_app_joins
        [
          [1001, 200],
          [1001, 202],
          [1001, 204],
        ]
      end
    end  # OneAppManySimilarlyNamedEnvs
  end
end

run FakeAwsm.new
