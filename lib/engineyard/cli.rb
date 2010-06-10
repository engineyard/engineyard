require 'engineyard'
require 'engineyard/error'
require 'engineyard/thor'

module EY
  class CLI < EY::Thor
    autoload :API,     'engineyard/cli/api'
    autoload :UI,      'engineyard/cli/ui'
    autoload :Recipes, 'engineyard/cli/recipes'
    autoload :Web,     'engineyard/cli/web'

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
    def deploy(env_name = nil, branch = nil)
      app           = api.app_for_repo!(repo)
      environment   = fetch_environment(env_name, app)
      deploy_branch = environment.resolve_branch(branch, options[:force]) ||
        repo.current_branch ||
        raise(DeployArgumentError)

      EY.ui.info "Connecting to the server..."

      loudly_check_eysd(environment)

      EY.ui.info "Running deploy for '#{environment.name}' on server..."

      if environment.deploy!(app, deploy_branch, options[:migrate])
        EY.ui.info "Deploy complete"
      else
        raise EY::Error, "Deploy failed"
      end

    rescue NoEnvironmentError => e
      # Give better feedback about why we couldn't find the environment.
      exists = api.environments.named(env_name)
      raise exists ? EnvironmentUnlinkedError.new(env_name) : e
    end

    desc "environments [--all]", "List cloud environments for this app, or all environments"
    method_option :all, :type => :boolean, :aliases => %(-a)
    def environments
      apps = get_apps(options[:all])
      EY.ui.warn(NoAppError.new(repo).message) unless apps.any? || options[:all]
      EY.ui.print_envs(apps, EY.config.default_environment)
    end
    map "envs" => :environments

    desc "rebuild [ENVIRONMENT]", "Rebuild environment (ensure configuration is up-to-date)"
    def rebuild(name = nil)
      env = fetch_environment(name)
      EY.ui.debug("Rebuilding #{env.name}")
      env.rebuild
    end

    desc "rollback [ENVIRONMENT]", "Rollback to the previous deploy"
    def rollback(name = nil)
      app    = api.app_for_repo!(repo)
      env    = fetch_environment(name)

      if env.app_master
        EY.ui.info("Rolling back #{env.name}")
        if env.rollback!(app)
          EY.ui.info "Rollback complete"
        else
          raise EY::Error, "Rollback failed"
        end
      else
        raise NoAppMaster.new(env.name)
      end
    end

    desc "ssh [ENVIRONMENT]", "Open an ssh session to the environment's application server"
    def ssh(name = nil)
      env = fetch_environment(name)

      if env.app_master
        Kernel.exec "ssh", "#{env.username}@#{env.app_master.public_hostname}"
      else
        raise NoAppMaster.new(env.name)
      end
    end

    desc "logs [ENVIRONMENT]", "Retrieve the latest logs for an environment"
    def logs(name = nil)
      env = fetch_environment(name)
      env.logs.each do |log|
        EY.ui.info log.instance_name

        if log.main
          EY.ui.info "Main logs for #{env.name}:"
          EY.ui.say  log.main
        end

        if log.custom
          EY.ui.info "Custom logs for #{env.name}:"
          EY.ui.say  log.custom
        end
      end
    end

    desc "recipes COMMAND [ARGS]", "Commands related to custom recipes"
    subcommand "recipes", EY::CLI::Recipes

    desc "web COMMAND [ARGS]", "Commands related to maintenance pages"
    subcommand "web", EY::CLI::Web

    desc "version", "Print the version of the engineyard gem"
    def version
      EY.ui.say %{engineyard version #{EY::VERSION}}
    end
    map ["-v", "--version"] => :version

  end # CLI
end # EY
