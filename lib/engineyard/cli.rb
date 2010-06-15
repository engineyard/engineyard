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
      Thor::Base.shell = EY::CLI::UI
      EY.ui = EY::CLI::UI.new
      super
    end

    desc "deploy [ENVIRONMENT] [BRANCH]", <<-DESC
Deploy specified branch to specified environment.

This command must be run with the current directory containing the app to be
deployed. If ey.yml specifies a default branch then the branch parameter can be
omitted. Furthermore, if a default branch is specified but a different command
is supplied the deploy will fail unless --force is used.

Migrations are run by default with 'rake db:migrate'. A different command can be
specified via --migrate "ruby do_migrations.rb". Migrations can also be skipped
entirely by using --no-migrate.
    DESC
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

      if environment.deploy(app, deploy_branch, options[:migrate])
        EY.ui.info "Deploy complete"
      else
        raise EY::Error, "Deploy failed"
      end

    rescue NoEnvironmentError => e
      # Give better feedback about why we couldn't find the environment.
      exists = api.environments.named(env_name)
      raise exists ? EnvironmentUnlinkedError.new(env_name) : e
    end

    desc "environments [--all]", <<-DESC
List environments.

By default, environments for this app are displayed. If the -all option is
used, all environments are displayed instead.
    DESC

    method_option :all, :type => :boolean, :aliases => %(-a)
    def environments
      apps = get_apps(options[:all])
      EY.ui.warn(NoAppError.new(repo).message) unless apps.any? || options[:all]
      EY.ui.print_envs(apps, EY.config.default_environment)
    end
    map "envs" => :environments

    desc "rebuild [ENVIRONMENT]", <<-DESC
Rebuild specified environment.

Engine Yard's main configuration run occurs on all servers. Mainly used to fix
failed configuration of new or existing servers, or to update servers to latest
Engine Yard stack (e.g. to apply an Engine Yard supplied security
patch).

Note that uploaded recipes are also run after the main configuration run has
successfully completed.
    DESC

    def rebuild(name = nil)
      env = fetch_environment(name)
      EY.ui.debug("Rebuilding #{env.name}")
      env.rebuild
    end

    desc "rollback [ENVIRONMENT]", <<-DESC
Rollback to the previous deploy.

Uses code from previous deploy in the "/data/APP_NAME/releases" directory on
remote server(s) to restart application servers.
   DESC

    def rollback(name = nil)
      app = api.app_for_repo!(repo)
      env = fetch_environment(name)

      loudly_check_eysd(env)

      EY.ui.info("Rolling back #{env.name}")
      if env.rollback(app)
        EY.ui.info "Rollback complete"
      else
        raise EY::Error, "Rollback failed"
      end
    end

    desc "ssh [ENVIRONMENT]", <<-DESC
Open an ssh session.

If the environment contains just one server, a session to it will be opened. For
environments with clusters, a session will be opened to the application master.
    DESC

    def ssh(name = nil)
      env = fetch_environment(name)

      if env.app_master
        Kernel.exec "ssh", "#{env.username}@#{env.app_master.public_hostname}"
      else
        raise NoAppMaster.new(env.name)
      end
    end

    desc "logs [ENVIRONMENT]", <<-DESC
Retrieve the latest logs for an environment.

Displays Engine Yard configuration logs for all servers in the environment. If
recipes were uploaded to the environment & run, their logs will also be
displayed beneath the main configuration logs.
    DESC

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

    desc "recipes", "Commands related to chef recipes."
    subcommand "recipes", EY::CLI::Recipes

    desc "web", "Commands related to maintenance pages."
    subcommand "web", EY::CLI::Web

    desc "version", "Print version number."
    def version
      EY.ui.say %{engineyard version #{EY::VERSION}}
    end
    map ["-v", "--version"] => :version

    desc "help [COMMAND]", "Describe all commands or one specific command."
    def help(*cmds)
      if cmds.empty?
        super
        EY.ui.say "See '#{self.class.send(:banner_base)} help [COMMAND]' for more information on a specific command."
      elsif klass = EY::Thor.subcommands[cmds.first]
        klass.new.help(*cmds[1..-1])
      else
        super
      end
    end
  end # CLI
end # EY
