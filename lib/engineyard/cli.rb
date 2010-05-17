require 'thor'
require 'engineyard'
require 'engineyard/error'
require 'engineyard/cli/thor_fixes'

module EY
  class CLI < Thor
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
      :default => 'rake db:migrate',
      :desc => "Run migrations via [MIGRATE], defaults to 'rake db:migrate'; use --no-migrate to avoid running migrations"
    method_option :install_eysd, :type => :boolean, :aliases => %(-s),
      :desc => "Force remote install of eysd"
    def deploy(env_name = nil, branch = nil)
      require 'engineyard/action/deploy'
      EY::Action::Deploy.call(env_name, branch, options)
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

    desc "rebuild [ENV]", "Rebuild environment (ensure configuration is up-to-date)"
    def rebuild(name = nil)
      require 'engineyard/action/rebuild'
      EY::Action::Rebuild.call(name)
    end

    desc "ssh ENV", "Open an ssh session to the environment's application server"
    def ssh(name)
      env = account.environment_named(name)
      if env
        Kernel.exec "ssh", "#{env.username}@#{env.app_master.public_hostname}", *ARGV[2..-1]
      else
        EY.ui.warn %|Could not find an environment named "#{name}"|
      end
    end

    desc "logs ENV", "Retrieve the latest logs for an enviornment"
    def logs(name)
      env_named(name).logs.each do |log|
        EY.ui.info log.instance_name

        if log.main
          EY.ui.info "Main logs:"
          EY.ui.say  log.main
        end

        if log.custom
          EY.ui.info "Custom logs:"
          EY.ui.say  log.custom
        end
      end
    end

    desc "upload_recipes ENV", "Upload custom chef recipes from the current directory to ENV"
    def upload_recipes(name)
      if account.upload_recipes_for(env_named(name))
        EY.ui.say "Recipes uploaded successfully"
      else
        EY.ui.error "Recipes upload failed"
      end
    end

    desc "version", "Print the version of the engineyard gem"
    def version
      EY.ui.say %{engineyard version #{EY::VERSION}}
    end
    map ["-v", "--version"] => :version

    private
    def account
      @account ||= EY::Account.new(EY::CLI::API.new)
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def env_named(env_name)
      env = account.environment_named(env_name)

      if env.nil?
        raise EnvironmentError, "Environment '#{env_name}' can't be found\n" +
          "You can create it at #{EY.config.endpoint}"
      end

      env
    end

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

  end # CLI
end # EY
