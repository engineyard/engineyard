module Scenario
  class Base
    attr_accessor :git_remote
    attr_reader :user

    def initialize(name = "User Name", email = "test@test.test", pass = "test")
      @git_remote = "user@git.host:path/to/repo.git"
      @user = User.create(:name => name, :email => email, :password => pass)
      @account = @user.accounts.create({"name" => "main"})
    end
  end

  class LinkedApp < Base
    def initialize(*)
      super('Linked App', 'linked.app@test.local', 'linked')
      @app = @account.apps.create("name" => "rails232app", "repository_uri" => git_remote)
      @env = @account.environments.create({
        "name" => "giblets",
        "ssh_username" => "turkey",
        "app_server_stack_name" => "nginx_mongrel",
        "load_balancer_ip_address" => '127.0.0.0',
        "framework_env" => "production"
      })

      _instances.each do |inst|
        @env.instances.create(inst)
      end
      @app_env = @app.app_environments.create(:environment => @env)
    end

    private

    def _instances
      [{
        "role" => "app_master",
        "name" => nil,
        "status" => "running",
        "amazon_id" => 'i-ddbbdd92',
        "public_hostname" => "app_master_hostname.compute-1.amazonaws.com",
      }, {
        "name" => nil,
        "role" => "db_master",
        "status" => "running",
        "amazon_id" => "i-d4cdddbf",
        "public_hostname" => "db_master_hostname.compute-1.amazonaws.com",
      }, {
        "name" => nil,
        "role" => "db_slave",
        "status" => "running",
        "amazon_id" => "i-asdfasdfaj",
        "public_hostname" => "db_slave_1_hostname.compute-1.amazonaws.com",
      }, {
        "name" => nil,
        "role" => "db_slave",
        "status" => "running",
        "amazon_id" => "i-asdfasdfaj",
        "public_hostname" => "db_slave_2_hostname.compute-1.amazonaws.com",
      }, {
        "role" => "app",
        "name" => nil,
        "status" => "building",
        "amazon_id" => "i-d2e3f1b9",
        "public_hostname" => "app_hostname.compute-1.amazonaws.com",
      }, {
        "role" => "util",
        "name" => "fluffy",
        "status" => "running",
        "amazon_id" => "i-80e3f1eb",
        "public_hostname" => "util_fluffy_hostname.compute-1.amazonaws.com",
      }, {
        "role" => "util",
        "name" => "rocky",
        "status" => "running",
        "amazon_id" => "i-80etf1eb",
        "public_hostname" => "util_rocky_hostname.compute-1.amazonaws.com",
      }]
    end
  end  # LinkedApp

  class MultipleAmbiguousAccounts < LinkedApp
    def initialize(*)
      super('Multiple Ambiguous Accounts', 'multiple.ambiguous.accounts@test.local', 'multi')
      @account2 = @user.accounts.create("name" => "account_2")
      @app2 = @account2.apps.create("name" => "rails232app", "repository_uri" => git_remote)
      @env2 = @account2.environments.create({
        "name" => "giblets",
        "ssh_username" => "turkey",
        "app_server_stack_name" => "nginx_mongrel",
        "load_balancer_ip_address" => '127.0.0.0',
        "framework_env" => "production"
      })

      _instances.each do |inst|
        @env2.instances.create(inst)
      end
      @app_env2 = @app2.app_environments.create(:environment => @env2)
    end
  end

  class UnlinkedApp < Base
    def initialize(*)
      super('Unlinked App', 'unlinked.app@test.local', 'unlinked')

      @app = @account.apps.create({
        "name" => "rails232app",
        "repository_uri" => git_remote
      })

      @env = @account.environments.create({
        "name" => "giblets",
        "ssh_username" => "turkey",
        "app_server_stack_name" => "nginx_mongrel",
        "load_balancer_ip_address" => '127.0.0.0',
        "framework_env" => "production"
      })

      @env.instances.create({
        "status" => "running",
        "amazon_id" => 'i-ddbbdd92',
        "role" => "solo",
        "public_hostname" => "ec2-174-129-198-124.compute-1.amazonaws.com"
      })
    end
  end # UnlinkedApp

  class LinkedAppNotRunning < Base
    def initialize(*)
      super('Linked App Not Running', 'linked.app.not.running@test.local', 'linked.stopped')
      @app = @account.apps.create({
        "name" => "rails232app",
        "repository_uri" => git_remote
      })

      @env = @account.environments.create({
        "ssh_username" => "turkey",
        "instances" => [],
        "name" => "giblets",
        "app_server_stack_name" => "nginx_mongrel",
        "load_balancer_ip_address" => '127.0.0.0',
        "framework_env" => "production"
      })

      @app.app_environments.create(:environment => @env)
    end
  end # LinkedAppNotRunning

  class LinkedAppRedMaster < LinkedApp
    def initialize(*)
      super('Linked App Red Master', 'linked.app.red.master@test.local', 'linked.red')
      @env.instances.first.update(:status => "error")
    end
  end

  class OneAppManyEnvs < Base
    def initialize(*)
      super('One App Many Envs', 'one.app.many.envs@test.local', '1app2cups')
      @app = @account.apps.create({
        "name" => "rails232app",
        "repository_uri" => git_remote
      })

      @env1 = @account.environments.create({
        "ssh_username" => "turkey",
        "name" => "giblets",
        "app_server_stack_name" => "nginx_mongrel",
        "load_balancer_ip_address" => '127.0.0.0',
        "framework_env" => "production",
      })
      @env1.app_environments.create(:app => @app)

      @env1.instances.create({
        "status" => "running",
        "amazon_id" => 'i-ddbbdd92',
        "role" => "solo",
        "public_hostname" => "app_master_hostname.compute-1.amazonaws.com"
      })
      @env2 = @account.environments.create({
        "ssh_username" => "ham",
        "instances" => [],
        "name" => "bakon",
        "app_server_stack_name" => "nginx_passenger",
        "load_balancer_ip_address" => '127.0.0.0',
      })
      @env2.app_environments.create(:app => @app)

      @env3 = @account.environments.create({
        "ssh_username" => "hamburger",
        "instances" => [],
        "name" => "beef",
        "app_server_stack_name" => "nginx_passenger",
        "load_balancer_ip_address" => '127.0.0.0',
      })
    end
  end # OneAppTwoEnvs

  class TwoApps < Base
    def initialize(*)
      super('Two Apps', 'two.apps@test.local', '2apps')
      @env1 = @account.environments.create({
          "name" => "giblets",
          "framework_env" => "staging",
          "ssh_username" => "turkey",
          "app_server_stack_name" => "nginx_unicorn",
          "load_balancer_ip_address" => '127.0.0.0',
      })
      @app1 = @account.apps.create({
        "name" => "rails232app",
        "repository_uri" => "git://github.com/smerritt/rails232app.git"
      })
      @env1.app_environments.create(:app => @app1)
      @env1.instances.create({
        "status" => "running",
        "name" => nil,
        "role" => "solo",
        "public_hostname" => "ec2-174-129-7-113.compute-1.amazonaws.com",
        "amazon_id" => "i-0911f063",
      })

      @env2 = @account.environments.create({
        "framework_env" => "production",
        "name" => "keycollector_production",
        "ssh_username" => "deploy",
        "load_balancer_ip_address" => '127.0.0.0',
        "app_server_stack_name" => "nginx_mongrel",
      })
      @app2 = @account.apps.create({
        "name" => "keycollector",
        "repository_uri" => "git@github.com:smerritt/keycollector.git",
      })
      @env2.app_environments.create(:app => @app2)
      @env2.instances.create({
        "status" => "running",
        "name" => nil,
        "role" => "solo",
        "public_hostname" => "app_master_hostname.compute-1.amazonaws.com",
        "amazon_id" => "i-051195b9",
      })
    end
  end # TwoApps

  class TwoAppsSameGitUri < TwoApps
    def initialize(*)
      super('Two Apps Same Git URI', 'two.apps.same.git.uri@test.local', '2apps1repo')
      @app1.update(:repository_uri => "git://github.com/engineyard/dup.git")
      @app2.update(:repository_uri => "git://github.com/engineyard/dup.git")
    end
  end # TwoAppsSameGitUri

  class OneAppManySimilarlyNamedEnvs < Base
    def initialize(*)
      super('One App Similarly Named Envs', 'one.app.similarly.named.envs@test.local', '1apptwinrepos')
      @app = @account.apps.create({
        "name" => "rails232app",
        "repository_uri" => git_remote
      })

      @env1 = @account.environments.create({
        "ssh_username" => "turkey",
        "name" => "railsapp_production",
        "load_balancer_ip_address" => '127.0.0.0',
        "app_server_stack_name" => "nginx_mongrel",
        "framework_env" => "production",
      })
      @env1.instances.create({
        "status" => "running",
        "amazon_id" => 'i-ddbbdd92',
        "role" => "solo",
        "public_hostname" => "app_master_hostname.compute-1.amazonaws.com"
      })

      @env2 = @account.environments.create({
        "ssh_username" => "ham",
        "name" => "railsapp_staging",
        "load_balancer_ip_address" => '127.3.2.1',
        "app_server_stack_name" => "nginx_passenger",
        "framework_env" => "production",
      })

      @env2.instances.create({
        "public_hostname" => '127.3.2.1',
        "status" => "running",
        "role" => "solo",
      })
      @env3 = @account.environments.create({
        "ssh_username" => "ham",
        "name" => "railsapp_staging_2",
        "app_server_stack_name" => "nginx_passenger",
        "load_balancer_ip_address" => '127.0.0.2',
        "framework_env" => "production",
      })
      @env3.instances.create({
        "status" => "running",
        "role" => "solo",
        "public_hostname" => "ec2-174-129-198-124.compute-1.amazonaws.com",
      })

      @app.app_environments.create(:environment => @env1)
      @app.app_environments.create(:environment => @env2)
      @app.app_environments.create(:environment => @env3)
    end
  end  # OneAppManySimilarlyNamedEnvs
end
