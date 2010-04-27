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
                   when "one app, two environments"
                     Scenario::OneAppTwoEnvs
                   end
    if new_scenario
      @@scenario = new_scenario
      {"ok" => "true"}.to_json
    else
      status(400)
      {"ok" => "false", "message" => "wtf is the #{params[:scenario]} scenario?"}.to_json
    end
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

  post "/api/v2/environments/:env_id/recipes" do
    {}.to_json
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

  module FindableGitRemote
    # Since we have to find something in `git remote -v` that
    # corresponds to an app in cloud.ey in order to do anything, we
    # simulate this by faking out the API to have whatever git
    # remote we'll find anyway.
    def git_remote
      remotes = []
      `git remote -v`.each_line do |line|
        parts = line.split(/\t/)
        # the remote will look like
        # "git@github.com:engineyard/engineyard.git (fetch)\n"
        # so we need to chop it up a bit
        remotes << parts[1].gsub(/\s.*$/, "") if parts[1]
      end
      remotes.first
    end
  end

  module Scenario
    class Empty
      def self.apps
        []
      end

      def self.environments
        []
      end
    end

    class UnlinkedApp
      extend FindableGitRemote

      def self.apps
        [{
            "name" => "rails232app",
            "environments" => [],
            "repository_uri" => git_remote}]
      end

      def self.environments
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
    end

    class LinkedApp
      extend FindableGitRemote

      def self.apps
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

      def self.environments
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

      def self.logs(env_id)
        [{
          "id" => env_id,
          "role" => "app_master",
          "main" => "MAIN LOG OUTPUT",
          "custom" => "CUSTOM LOG OUTPUT"
        }]
      end
    end

    class OneAppTwoEnvs
      extend FindableGitRemote

      def self.apps
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

      def self.environments
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
    end
  end
end

run FakeAwsm.new
