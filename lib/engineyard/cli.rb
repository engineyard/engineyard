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

    desc "deploy [--environment ENVIRONMENT] [--ref GIT-REF]",
      "Deploy specified branch, tag, or sha to specified environment."
    long_desc <<-DESC
      This command must be run with the current directory containing the app to be
      deployed. If ey.yml specifies a default branch then the ref parameter can be
      omitted. Furthermore, if a default branch is specified but a different command
      is supplied the deploy will fail unless --force is used.

      Migrations are run by default with 'rake db:migrate'. A different command can be
      specified via --migrate "ruby do_migrations.rb". Migrations can also be skipped
      entirely by using --no-migrate.
    DESC
    method_option :force, :type => :boolean, :aliases => %w(-f),
      :desc => "Force a deploy of the specified branch even if a default is set"
    method_option :migrate, :type => :string, :aliases => %w(-m),
      :default => 'rake db:migrate',
      :desc => "Run migrations via [MIGRATE], defaults to 'rake db:migrate'; use --no-migrate to avoid running migrations"
    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Environment in which to deploy this application"
    method_option :ref, :type => :string, :aliases => %w(-r --branch --tag),
      :desc => "Git ref to deploy. May be a branch, a tag, or a SHA."
    method_option :app, :type => :string, :aliases => %w(-a),
      :desc => "Name of the application to deploy"
    def deploy
      app         = api.fetch_app!(options[:app]) || api.app_for_repo!(repo)
      environment = fetch_environment(options[:environment], app)
      deploy_ref  = if options[:app]
                      environment.resolve_branch(options[:ref], options[:force]) ||
                        raise(EY::Error, "When specifying the application, you must also specify the ref to deploy\nUsage: ey deploy --app <app name> --ref <branch|tag|ref>")
                    else
                      environment.resolve_branch(options[:ref], options[:force]) ||
                        repo.current_branch ||
                        raise(DeployArgumentError)
                    end

      EY.ui.info "Connecting to the server..."

      loudly_check_eysd(environment)

      EY.ui.info "Running deploy for '#{environment.name}' on server..."

      if environment.deploy(app, deploy_ref, options[:migrate])
        EY.ui.info "Deploy complete"
      else
        raise EY::Error, "Deploy failed"
      end

    rescue NoEnvironmentError => e
      # Give better feedback about why we couldn't find the environment.
      exists = api.environments.named(options[:environment])
      raise exists ? EnvironmentUnlinkedError.new(options[:environment]) : e
    end

    desc "environments [--all]", "List environments."
    long_desc <<-DESC
      By default, environments for this app are displayed. The --all option will
      display all environments, including those for this app.
    DESC

    method_option :all, :type => :boolean, :aliases => %(-a)
    def environments
      apps = get_apps(options[:all])
      EY.ui.warn(NoAppError.new(repo).message) unless apps.any? || options[:all]
      EY.ui.print_envs(apps, EY.config.default_environment)
    end
    map "envs" => :environments

    desc "rebuild [--environment ENVIRONMENT]", "Rebuild specified environment."
    long_desc <<-DESC
      Engine Yard's main configuration run occurs on all servers. Mainly used to fix
      failed configuration of new or existing servers, or to update servers to latest
      Engine Yard stack (e.g. to apply an Engine Yard supplied security
      patch).

      Note that uploaded recipes are also run after the main configuration run has
      successfully completed.
    DESC

    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Environment to rebuild"
    def rebuild
      env = fetch_environment(options[:environment])
      EY.ui.debug("Rebuilding #{env.name}")
      env.rebuild
    end

    desc "rollback [--environment ENVIRONMENT]", "Rollback to the previous deploy."
    long_desc <<-DESC
      Uses code from previous deploy in the "/data/APP_NAME/releases" directory on
      remote server(s) to restart application servers.
    DESC
    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Environment in which to roll back the current application"
    def rollback
      app = api.app_for_repo!(repo)
      env = fetch_environment(options[:environment])

      loudly_check_eysd(env)

      EY.ui.info("Rolling back #{env.name}")
      if env.rollback(app)
        EY.ui.info "Rollback complete"
      else
        raise EY::Error, "Rollback failed"
      end
    end

    desc "ssh [--environment ENVIRONMENT]", "Open an ssh session."
    long_desc <<-DESC
      If the environment contains just one server, a session to it will be opened. For
      environments with clusters, a session will be opened to the application master.
    DESC
    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Environment to ssh into"
    def ssh
      env = fetch_environment(options[:environment])

      if env.app_master
        Kernel.exec "ssh", "#{env.username}@#{env.app_master.public_hostname}"
      else
        raise NoAppMaster.new(env.name)
      end
    end

    desc "logs [--environment ENVIRONMENT]", "Retrieve the latest logs for an environment."
    long_desc <<-DESC
      Displays Engine Yard configuration logs for all servers in the environment. If
      recipes were uploaded to the environment & run, their logs will also be
      displayed beneath the main configuration logs.
    DESC
    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Environment with the interesting logs"
    def logs
      env = fetch_environment(options[:environment])
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
        base = self.class.send(:banner_base)
        list = self.class.printable_tasks

        EY.ui.say "Usage:"
        EY.ui.say "  #{base} [--help] [--version] COMMAND [ARGS]"
        EY.ui.say

        EY.ui.say "Deploy commands:"
        deploy_cmds = %w(deploy environments logs rebuild rollback)
        deploy_cmds.map! do |name|
          list.find{|task| task[0] =~ /^#{base} #{name}/ }
        end
        list = list - deploy_cmds
        EY.ui.print_table(deploy_cmds, :ident => 2, :truncate => true)
        EY.ui.say

        EY::Thor.subcommands.each do |name, klass|
          list.reject!{|cmd| cmd[0] =~ /^#{base} #{name}/}
          EY.ui.say "#{name.capitalize} commands:"
          EY.ui.print_table(klass.printable_tasks, :ident => 2, :truncate => true)
          EY.ui.say
        end

        %w(help version).each{|n| list.reject!{|c| c[0] =~ /^#{base} #{n}/ } }
        if list.any?
          EY.ui.say "Other commands:"
          EY.ui.print_table(list, :ident => 2, :truncate => true)
          EY.ui.say
        end

        self.class.send(:class_options_help, shell)
        EY.ui.say "See '#{base} help COMMAND' for more information on a specific command."
      elsif klass = EY::Thor.subcommands[cmds.first]
        klass.new.help(*cmds[1..-1])
      else
        super
      end
    end

  end # CLI
end # EY
