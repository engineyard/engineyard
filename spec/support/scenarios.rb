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
          "app_server_stack_name" => "nginx_mongrel",
          "load_balancer_ip_address" => '127.0.0.0',
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
          "id" => 200,
          "app_server_stack_name" => "nginx_mongrel",
          "load_balancer_ip_address" => '127.0.0.0',
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
          "id" => 200,
          "app_server_stack_name" => "nginx_mongrel",
          "load_balancer_ip_address" => '127.0.0.0',
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
          "id" => 200,
          "app_server_stack_name" => "nginx_mongrel",
          "load_balancer_ip_address" => '127.0.0.0',
          "framework_env" => "production",
        }, {
          "ssh_username" => "ham",
          "instances" => [],
          "name" => "bakon",
          "instances_count" => 0,
          "app_server_stack_name" => "nginx_passenger",
          "load_balancer_ip_address" => '127.0.0.0',
          "id" => 202,
        }, {
          "ssh_username" => "hamburger",
          "instances" => [],
          "name" => "beef",
          "instances_count" => 0,
          "app_server_stack_name" => "nginx_passenger",
          "load_balancer_ip_address" => '127.0.0.0',
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
          "app_server_stack_name" => "nginx_unicorn",
          "load_balancer_ip_address" => '127.0.0.0',
        }, {
          "id" => 439,
          "framework_env" => "production",
          "name" => "keycollector_production",
          "ssh_username" => "deploy",
          "instances_count" => 1,
          "load_balancer_ip_address" => '127.0.0.0',
          "app_server_stack_name" => "nginx_mongrel",
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
          "load_balancer_ip_address" => '127.0.0.0',
          "app_server_stack_name" => "nginx_mongrel",
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
          "load_balancer_ip_address" => '127.3.2.1',
          "app_server_stack_name" => "nginx_passenger",
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
          "app_server_stack_name" => "nginx_passenger",
          "id" => 204,
          "load_balancer_ip_address" => '127.0.0.2',
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
