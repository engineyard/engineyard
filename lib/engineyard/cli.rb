$:.unshift File.expand_path('../../vendor', __FILE__)
require 'thor'
require 'engineyard'

module EY
  class CLI < Thor
    autoload :Token,  'engineyard/cli/token'
    autoload :UI,     'engineyard/cli/ui'

    include Thor::Actions

    def self.start
      EY.ui = EY::CLI::UI.new
      super
    end

    desc "deploy [ENVIRONMENT] [BRANCH]", "Deploy [BRANCH] of the app in the current directory to [ENVIRONMENT]"
    method_option :force, :type => :boolean, :aliases => %w(-f), :desc => "Force a deploy of the specified branch"
    method_option :migrate, :type => :boolean, :default => true, :aliases => %w(-m), :desc => "Run migrations after deploy"
    method_option :install_eysd, :type => :boolean, :aliases => %(-s), :desc => "Force remote install of eysd"
    def deploy(env_name = nil, branch = nil)
      env_name ||= config.default_environment
      raise RequiredArgumentMissingError, "[ENVIRONMENT] not provided" unless env_name

      default_branch = config.default_branch(env_name)
      branch ||= (default_branch || repo.current_branch)
      raise RequiredArgumentMissingError, "[BRANCH] not provided" unless branch

      if default_branch && (branch != default_branch) && !options[:force]
        raise BranchMismatch, %{Your deploy branch is set to "#{default_branch}".\n} +
        %{If you want to deploy branch "#{branch}", use --force.}
      end

      app = account.app_for_url(repo.url)
      raise EnvironmentError, "No cloud application configured for repository at '#{repo.url}'" unless app
      env = app["environments"].find{|e| e["name"] == env_name }
      raise EnvironmentError, "No cloud environment named '#{env_name}' running this app" unless env

      # OMG EY cloud quotes nulls when it returns JSON :(
      app_master = env["app_master"] != "null" && env["app_master"]
      raise EnvironmentError, "No running app master" unless app_master && app_master["status"] == "running"
      ip = app_master["ip_address"]

      EY.ui.info "Connecting to the server..."
      eysd_installed = ssh(ip, "which eysd", false)
      raise EnvironmentError, "SSH connection to #{ip} failed" if $?.exitstatus == 255

      if !eysd_installed || options[:install_eysd]
        EY.ui.info "Installing ey-deploy gem..."
        gem_file = Dir["ey-deploy*.gem"].first
        if gem_file
          system %{scp #{gem_file} root@#{ip}:~/}
        else
          raise EY::Error "Could not find ey-deploy gem file in the current directory"
        end
        ssh(ip, "gem install #{gem_file}")
      end

      deploy_cmd = "eysd update --app #{app["name"]} --branch #{branch}"
      if options[:migrate]
        deploy_cmd << " --migrate"
      else
        deploy_cmd << " --no-migration-command"
      end

      EY.ui.info "Running deploy on server..."
      ssh(ip, deploy_cmd)

      EY.ui.info "Deploy complete."
    end


    desc "targets", "List environments that are deploy targets for the app in the current directory"
    def targets
      app = account.app_for_url(repo.url)
      if !app
        EY.ui.warn %{You have no cloud applications configured for the repository "#{repo.url}".}
      else
        envs = app["environments"]
        if envs.empty?
          EY.ui.warn %{You have no cloud environments set up for the application "#{app["name"]}".}
        else
          EY.ui.say %{Cloud environments for #{app["name"]}:}
          EY.ui.print_envs(envs, config.default_environment)
        end
      end
    end


    desc "environments", "All cloud environments"
    def environments
      envs = account.environments
      if envs.empty?
        EY.ui.say %{You do not have any cloud environments.}
      else
        EY.ui.say %{Cloud environments:}
        EY.ui.print_envs(envs, config.default_environment)
      end
    end

  private

    def account
      @account ||= EY::Account.new(Token.new)
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def config
      @config ||= EY::Config.new
    end

    def debug(*args)
      EY.ui.debug(*args)
    end

    def ssh(ip, remote_cmd, output = true)
      cmd = %{ssh root@#{ip} "#{remote_cmd}"}
      cmd << %{ &> /dev/null} unless output
      puts cmd if output
      system cmd
    end

    end
  end # CLI
end # EY
