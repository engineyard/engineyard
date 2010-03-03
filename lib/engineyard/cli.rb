$:.unshift File.expand_path('../../vendor', __FILE__)
require 'thor'

module EY
  class CLI < Thor
    EYSD_VERSION = "~>0.1.3"

    autoload :API, 'engineyard/cli/api'
    autoload :UI,  'engineyard/cli/ui'

    include Thor::Actions

    def self.start(*)
      EY.ui = EY::CLI::UI.new
      super
    end

    desc "deploy [ENVIRONMENT] [BRANCH]", "Deploy [BRANCH] of the app in the current directory to [ENVIRONMENT]"
    method_option :force, :type => :boolean, :aliases => %w(-f),
      :desc => "Force a deploy of the specified branch"
    method_option :migrate, :type => :string, :aliases => %w(-m), :default => 'rake db:migrate',
      :desc => "Run migrations via [MIGRATE], defaults to 'rake db:migrate'"
    method_option :install_eysd, :type => :boolean, :aliases => %(-s),
      :desc => "Force remote install of eysd"
    def deploy(env_name = nil, branch = nil)
      env_name ||= EY.config.default_environment
      raise RequiredArgumentMissingError, "[ENVIRONMENT] not provided" unless env_name

      default_branch = EY.config.default_branch(env_name)
      branch ||= (default_branch || repo.current_branch)
      raise RequiredArgumentMissingError, "[BRANCH] not provided" unless branch

      if default_branch && (branch != default_branch) && !options[:force]
        raise BranchMismatch, %{Your deploy branch is set to "#{default_branch}".\n} +
        %{If you want to deploy branch "#{branch}", use --force.}
      end

      app = account.app_for_repo(repo)
      raise EnvironmentError, "No cloud application configured for repository at '#{repo.url}'" unless app

      env = app.environments.find{|e| e.name == env_name }
      raise EnvironmentError, "No cloud environment named '#{env_name}' running this app" unless env

      running = env.app_master && env.app_master.status == "running"
      raise EnvironmentError, "No running app master for environment #{env.name}" unless running

      ip = app_master.ip_address

      EY.ui.info "Connecting to the server..."
      ssh(ip, "eysd check '#{EY::VERSION}' '#{EYSD_VERSION}'", false)
      case $?.exitstatus
      when 255
        raise EnvironmentError, "SSH connection to #{ip} failed"
      when 127
        EY.ui.warn "Server does not have ey-deploy gem installed"
        eysd_installed = false
      when 0
        eysd_installed = true
      else
        raise EnvironmentError, "ey-deploy version not compatible"
      end

      if !eysd_installed || options[:install_eysd]
        EY.ui.info "Installing ey-deploy gem..."
        ssh(ip, "gem install ey-deploy -v '#{EYSD_VERSION}'")
      end

      deploy_cmd = "eysd update --app #{app["name"]} --branch #{branch}"
      deploy_cmd << " --config '#{env.config.to_json}'" if env.config

      if options[:migrate]
        deploy_cmd << " --migrate='#{options[:migrate]}'"
      else
        deploy_cmd << " --no-migrate"
      end

      EY.ui.info "Running deploy on server..."
      deployed = ssh(ip, deploy_cmd)

      if deployed
        EY.ui.info "Deploy complete"
      else
        raise EY::Error, "Deploy failed"
      end
    end


    desc "targets", "List environments that are deploy targets for the app in the current directory"
    def targets
      app = account.app_for_repo(repo)
      if !app
        EY.ui.warn %{You have no cloud applications configured for the repository "#{repo.url}".}
      else
        envs = app.environments
        if envs.empty?
          EY.ui.warn %{You have no cloud environments set up for the application "#{app["name"]}".}
        else
          EY.ui.say %{Cloud environments for #{app["name"]}:}
          EY.ui.print_envs(envs, EY.config.default_environment)
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
        EY.ui.print_envs(envs, EY.config.default_environment)
      end
    end


    desc "version", "Print the version of the engineyard gem"
    def version
      EY.ui.say %{engineyard version #{EY::VERSION}}
    end
    map "-v" => :version

  private

    def account
      @account ||= EY::Account.new(API.new)
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def debug(*args)
      EY.ui.debug(*args)
    end

    def ssh(ip, remote_cmd, output = true)
      cmd = %{ssh root@#{ip} "#{remote_cmd}"}
      cmd << %{ &> /dev/null} unless output
      EY.ui.debug(cmd)
      puts cmd if output
      system cmd unless ENV["NO_SSH"]
    end

  end # CLI
end # EY
