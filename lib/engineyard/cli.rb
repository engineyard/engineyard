$:.unshift File.expand_path('../../vendor', __FILE__)
require 'thor'

require 'engineyard'
require 'engineyard/cli/error'

module EY
  class CLI < Thor
    EYSD_VERSION = "~>0.2.4"

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
    method_option :migrate, :type => :string, :aliases => %w(-m),
      :desc => "Run migrations via [MIGRATE], defaults to 'rake db:migrate'"
    method_option :install_eysd, :type => :boolean, :aliases => %(-s),
      :desc => "Force remote install of eysd"
    def deploy(env_name = nil, branch = nil)
      app = account.app_for_repo(repo)
      raise NoAppError.new(repo) unless app

      env_name ||= EY.config.default_environment
      raise DeployArgumentError if !env_name && app.environments.size != 1

      default_branch = EY.config.default_branch(env_name)
      branch ||= (default_branch || repo.current_branch)
      raise DeployArgumentError unless branch

      invalid_branch = default_branch && (branch != default_branch) && !options[:force]
      raise BranchMismatch.new(default_branch, branch) if invalid_branch

      if env_name
        env = app.environments.find{|e| e.name == env_name }
      else
        env = app.environments.first
      end

      if !env && account.environment_named(env_name)
        raise EnvironmentError, "Environment '#{env_name}' doesn't run this application\nYou can add it at #{EY.config.endpoint}"
      elsif !env
        raise NoEnvironmentError
      end

      running = env.app_master && env.app_master.status == "running"
      raise EnvironmentError, "No running instances for environment #{env.name}\nStart one at #{EY.config.endpoint}" unless running

      hostname = env.app_master.public_hostname
      username = env.username

      EY.ui.info "Connecting to the server..."
      ssh_to(hostname, "eysd check '#{EY::VERSION}' '#{EYSD_VERSION}'", username, false)
      case $?.exitstatus
      when 255
        raise EnvironmentError, "SSH connection to #{hostname} failed"
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
        ssh_to(hostname,
            "sudo gem install ey-deploy -v '#{EYSD_VERSION}'",
            username)
      end

      deploy_cmd = "eysd deploy --app #{app.name} --branch #{branch}"
      if env.config
        escaped_config_option = env.config.to_json.gsub(/"/, "\\\"")
        deploy_cmd << " --config '#{escaped_config_option}'"
      end

      if options.key(:migrate)
        if options[:migrate]
          deploy_cmd << " --migrate='#{options[:migrate]}'"
        else
          deploy_cmd << " --no-migrate"
        end
      end

      EY.ui.info "Running deploy on server..."
      deployed = ssh_to(hostname, deploy_cmd, username)

      if deployed
        EY.ui.info "Deploy complete"
      else
        raise EY::Error, "Deploy failed"
      end
    end


    desc "environments [--all]", "List cloud environments for this app, or all environments"
    method_option :all, :type => :boolean, :aliases => %(-a)
    def environments
      app, envs = app_and_envs(options[:all])
      if app
        EY.ui.say %|Cloud environments for #{app.name}:|
        EY.ui.print_envs(envs, EY.config.default_environment)
      elsif envs
        EY.ui.say %|Cloud environments:|
        EY.ui.print_envs(envs, EY.config.default_environment)
      else
        EY.ui.say %|You do not have any cloud environments.|
      end
    end
    map "envs" => :environments

    desc "ssh ENV", "Open an ssh session to the environment's application server"
    def ssh(name)
      env = account.environment_named(name)
      if env
        Kernel.exec "ssh", "#{env.username}@#{env.app_master.public_hostname}", *ARGV[2..-1]
      else
        EY.ui.warn %|Could not find an environment named "#{name}"|
      end
    end

    desc "version", "Print the version of the engineyard gem"
    def version
      EY.ui.say %{engineyard version #{EY::VERSION}}
    end
    map "-v" => :version

  private

    def app_and_envs(all_envs = false)
      app = account.app_for_repo(repo)

      if all_envs || !app
        envs = account.environments
        EY.ui.warn(NoAppError.new(repo).message) unless app || all_envs
        [nil, envs]
      else
        envs = app.environments
        if envs.empty?
          EY.ui.warn %|You have no environments set up for the application "#{app.name}"|
          EY.ui.warn %|You can make one at #{EY.config.endpoint}|
        end
        envs.empty? ? [app, nil] : [app, envs]
      end
    end

    def account
      @account ||= EY::Account.new(API.new)
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def ssh_to(hostname, remote_cmd, user, output = true)
      cmd = %{ssh -o StrictHostKeyChecking=no -q #{user}@#{hostname} "#{remote_cmd}"}
      cmd << %{ &> /dev/null} unless output
      EY.ui.debug(cmd)
      puts cmd if output
      unless ENV["NO_SSH"]
        system cmd
      else
        true
      end
    end

  end # CLI
end # EY
