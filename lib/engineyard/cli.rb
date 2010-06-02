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
      require 'engineyard/cli/action/deploy'
      EY::CLI::Action::Deploy.call(env_name, branch, options)
    end

    desc "environments [--all]", "List cloud environments for this app, or all environments"
    method_option :all, :type => :boolean, :aliases => %(-a)
    def environments
      apps = get_apps(options[:all])
      EY.ui.warn(NoAppError.new(repo).message) unless apps.any? || options[:all]
      EY.ui.print_envs(apps, EY.config.default_environment)
    end
    map "envs" => :environments

    desc "rebuild [ENV]", "Rebuild environment (ensure configuration is up-to-date)"
    def rebuild(name = nil)
      env = fetch_environment(name)
      EY.ui.debug("Rebuilding #{env.name}")
      env.rebuild
    end

    desc "ssh [ENV]", "Open an ssh session to the environment's application server"
    def ssh(name = nil)
      env = fetch_environment(name)

      if env.app_master
        Kernel.exec "ssh", "#{env.username}@#{env.app_master.public_hostname}"
      else
        raise NoAppMaster.new(env.name)
      end
    end

    desc "logs [ENV]", "Retrieve the latest logs for an environment"
    def logs(name = nil)
      fetch_environment(name).logs.each do |log|
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
      if api.environments.match_one(name).upload_recipes
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
    def api
      @api ||= EY::CLI::API.new
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def fetch_environment(env_name)
      if env_name.nil?
        fetch_environment_from_app(api.fetch_app_for_repo(repo))
      else
        env = api.environments.match_one(env_name)

        if env.nil?
          raise EnvironmentError, "Environment '#{env_name}' can't be found\n" +
            "You can create it at #{EY.config.endpoint}"
        end

        env
      end
    end

    def fetch_environment_from_app(app)
      env = app.one_and_only_environment or raise NoSingleEnvironmentError.new(app)
    end

    def get_apps(all_apps = false)
      if all_apps
        api.apps
      else
        [api.app_for_repo(repo)].compact
      end
    end

  end # CLI
end # EY
