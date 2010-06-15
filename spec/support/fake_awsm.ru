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
    @@scenario = Scenario::Empty  # have to start somewhere
  end

  before { content_type "application/json" }

  get "/" do
    content_type :html
    "OMG"
  end

  put "/scenario" do
    new_scenario = case params[:scenario]
                   when "empty"
                     Scenario::Empty
                   when "one app, one environment, not linked"
                     Scenario::UnlinkedApp
                   when "one app, one environment"
                     Scenario::LinkedApp
                   when "one app, one environment, app master red"
                     Scenario::LinkedAppRedMaster
                   when "one app, two environments"
                     Scenario::OneAppTwoEnvs
                   when "one app, many similarly-named environments"
                     Scenario::OneAppManySimilarlyNamedEnvs
                   else
                     status(400)
                     return {"ok" => "false", "message" => "wtf is the #{params[:scenario]} scenario?"}.to_json
                   end
    @@scenario = new_scenario.new(params[:remote])
    {"ok" => "true"}.to_json
  end

  get "/api/v2/apps" do
    {"apps" => @@scenario.apps}.to_json
  end

  get "/api/v2/environments" do
    {"environments" => @@scenario.environments}.to_json
  end

  get "/api/v2/environments/:env_id/logs" do
    {"logs" => @@scenario.logs(params[:env_id])}.to_json
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

  module Scenario
    class Empty
      attr_reader :git_remote

      def initialize(git_remote)
        @git_remote = git_remote
      end

      def apps
        []
      end

      def environments
        []
      end
    end # Empty

    class UnlinkedApp < Empty
      def apps
        [{
            "name" => "rails232app",
            "environments" => [],
            "repository_uri" => git_remote}]
      end

      def environments
        [{
            "ssh_username" => "turkey",
            "instances" => [{
                "public_hostname" => "174.129.198.124",
                "status" => "running",
                "id" => 27220}],
            "name" => "giblets",
            "apps" => [],
            "instances_count" => 1,
            "stack_name" => "nginx_mongrel",
            "id" => 200,
            "app_master" => {
              "public_hostname" => "174.129.198.124",
              "status" => "running",
              "id" => 27220}}]
      end
    end # UnlinkedApp

    class LinkedApp < Empty
      def apps
        [{"name" => "rails232app",
            "environments" => [{"ssh_username" => "turkey",
                "instances" => [{"public_hostname" => "174.129.198.124",
                    "status" => "running",
                    "id" => 27220}],
                "name" => "giblets",
                "apps" => [{"name" => "rails232app",
                    "repository_uri" => git_remote}],
                "instances_count" => 1,
                "stack_name" => "nginx_mongrel",
                "id" => 200,
                "app_master" => {"public_hostname" => "174.129.198.124",
                  "status" => "running",
                  "id" => 27220}}],
            "repository_uri" => git_remote}]
      end

      def environments
        [{
            "ssh_username" => "turkey",
            "instances" => [{
                "public_hostname" => "174.129.198.124",
                "status" => "running",
                "id" => 27220}],
            "name" => "giblets",
            "apps" => [{
                "name" => "rails232app",
                "repository_uri" => git_remote}],
            "instances_count" => 1,
            "stack_name" => "nginx_mongrel",
            "id" => 200,
            "app_master" => {
              "public_hostname" => "174.129.198.124",
              "status" => "running",
              "id" => 27220}}]
      end

      def logs(env_id)
        [{
          "id" => env_id,
          "role" => "app_master",
          "main" => "MAIN LOG OUTPUT",
          "custom" => "CUSTOM LOG OUTPUT"
        }]
      end
    end # LinkedApp

    class LinkedAppRedMaster < LinkedApp
      def apps
        apps = super
        apps[0]["environments"][0]["instances"][0]["status"] = "error"
        apps[0]["environments"][0]["app_master"]["status"] = "error"
        apps
      end

      def environments
        envs = super
        envs[0]["instances"][0]["status"] = "error"
        envs[0]["app_master"]["status"] = "error"
        envs
      end
    end

    class OneAppTwoEnvs < Empty
      def apps
        apps = [{
            "name" => "rails232app",
            "repository_uri" => git_remote
          }]

        [{"name" => "rails232app",
            "environments" => [{
                "ssh_username" => "turkey",
                "instances" => [{"public_hostname" => "174.129.198.124",
                    "status" => "running",
                    "id" => 27220}],
                "name" => "giblets",
                "apps" => apps,
                "instances_count" => 1,
                "stack_name" => "nginx_mongrel",
                "id" => 200,
                "app_master" => {"public_hostname" => "174.129.198.124",
                  "status" => "running",
                  "id" => 27220}
              }, {
                "ssh_username" => "ham",
                "instances" => [],
                "name" => "bakon",
                "apps" => apps,
                "instances_count" => 0,
                "stack_name" => "nginx_passenger",
                "id" => 8371,
                "app_master" => nil,
              }],
            "repository_uri" => git_remote}]
      end

      def environments
        [{
            "ssh_username" => "turkey",
            "instances" => [{
                "public_hostname" => "174.129.198.124",
                "status" => "running",
                "id" => 27220}],
            "name" => "giblets",
            "apps" => [{
                "name" => "rails232app",
                "repository_uri" => git_remote}],
            "instances_count" => 1,
            "stack_name" => "nginx_mongrel",
            "id" => 200,
            "app_master" => {
              "public_hostname" => "174.129.198.124",
              "status" => "running",
              "id" => 27220}
          }, {
            "ssh_username" => "ham",
            "instances" => [],
            "name" => "bakon",
            "apps" => [{
                "name" => "rails232app",
                "repository_uri" => git_remote}],
            "instances_count" => 0,
            "stack_name" => "nginx_passenger",
            "id" => 8371,
            "app_master" => nil,
          }]
      end
    end # OneAppTwoEnvs

    class OneAppManySimilarlyNamedEnvs < Empty
      def apps
        apps = [{
            "name" => "rails232app",
            "repository_uri" => git_remote
          }]

        [{"name" => "rails232app",
            "environments" => [{
                "ssh_username" => "turkey",
                "instances" => [{
                    "public_hostname" => "174.129.198.124",
                    "status" => "running",
                    "id" => 27220}],
                "name" => "railsapp_production",
                "apps" => apps,
                "instances_count" => 1,
                "stack_name" => "nginx_mongrel",
                "id" => 200,
                "app_master" => {
                  "public_hostname" => "174.129.198.124",
                  "status" => "running",
                  "id" => 27220,
                },
              }, {
                "ssh_username" => "ham",
                "instances" => [{
                    "public_hostname" => '127.3.2.1',
                    "status" => "running",
                    "id" => 63066,
                  }],
                "name" => "railsapp_staging",
                "apps" => apps,
                "instances_count" => 1,
                "stack_name" => "nginx_passenger",
                "id" => 8371,
                "app_master" => {
                  "public_hostname" => '127.3.2.1',
                  "status" => "running",
                  "id" => 63066,
                },
              }, {
                "ssh_username" => "ham",
                "instances" => [{
                    "public_hostname" => '127.44.55.66',
                    "status" => "running",
                    "id" => 59395,
                  }],
                "name" => "railsapp_staging_2",
                "apps" => apps,
                "instances_count" => 1,
                "stack_name" => "nginx_passenger",
                "id" => 8371,
                "app_master" => {
                  "public_hostname" => '127.44.55.66',
                  "status" => "running",
                  "id" => 59395,
                },
              }],
            "repository_uri" => git_remote}]
      end

      def environments
        [{
            "ssh_username" => "turkey",
            "instances" => [{
                "public_hostname" => "174.129.198.124",
                "status" => "running",
                "id" => 27220}],
            "name" => "railsapp_production",
            "apps" => [{
                "name" => "rails232app",
                "repository_uri" => git_remote}],
            "instances_count" => 1,
            "stack_name" => "nginx_mongrel",
            "id" => 200,
            "app_master" => {
              "public_hostname" => "174.129.198.124",
              "status" => "running",
              "id" => 27220}
          }, {
            "ssh_username" => "ham",
            "instances" => [{
                "public_hostname" => '127.3.2.1',
                "status" => "running",
                "id" => 63066,
              }],
            "name" => "railsapp_staging",
            "apps" => [{
                "name" => "rails232app",
                "repository_uri" => git_remote}],
            "instances_count" => 1,
            "stack_name" => "nginx_passenger",
            "id" => 8371,
            "app_master" => {
              "public_hostname" => '127.3.2.1',
              "status" => "running",
              "id" => 63066,
            },
          }, {
            "ssh_username" => "chicken",
            "instances" => [{
                "public_hostname" => '127.44.55.66',
                "status" => "running",
                "id" => 59395,
              }],
            "name" => "railsapp_staging_2",
            "apps" => [{
                "name" => "rails232app",
                "repository_uri" => git_remote}],
            "instances_count" => 1,
            "stack_name" => "nginx_passenger",
            "id" => 8371,
            "app_master" => {
              "public_hostname" => '127.44.55.66',
              "status" => "running",
              "id" => 59395,
            },
          }]
      end

      def logs(env_id)
        [{
            "id" => env_id,
            "role" => "app_master",
            "main" => "MAIN LOG OUTPUT",
            "custom" => "CUSTOM LOG OUTPUT"
          }]
      end
    end  # OneAppManySimilarlyNamedEnvs
  end
end

run FakeAwsm.new
