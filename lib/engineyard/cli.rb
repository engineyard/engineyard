require 'engineyard'
require 'engineyard/error'
require 'engineyard/thor'
require 'engineyard/deploy_config'

module EY
  class CLI < EY::Thor
    require 'engineyard/cli/recipes'
    require 'engineyard/cli/web'
    require 'engineyard/cli/api'
    require 'engineyard/cli/ui'
    require 'engineyard/error'
    require 'engineyard-cloud-client/errors'

    include Thor::Actions

    def self.start(*)
      Thor::Base.shell = EY::CLI::UI
      EY.ui = EY::CLI::UI.new
      super
    rescue EY::Error, EY::CloudClient::Error => e
      EY.ui.print_exception(e)
      raise
    rescue Interrupt => e
      puts
      EY.ui.print_exception(e)
      EY.ui.say("Quitting...")
      raise
    end

    desc "deploy [--environment ENVIRONMENT] [--ref GIT-REF]",
      "Deploy specified branch, tag, or sha to specified environment."
    long_desc <<-DESC
      This command must be run with the current directory containing the app to be
      deployed. If ey.yml specifies a default branch then the ref parameter can be
      omitted. Furthermore, if a default branch is specified but a different command
      is supplied the deploy will fail unless -R or --force-ref is used.

      Migrations are run based on the settings in your ey.yml file.
      With each deploy the default migration setting can be overriden by
      specifying --migrate or --migrate 'rake db:migrate'.
      Migrations can also be skipped by using --no-migrate.
    DESC
    method_option :ignore_bad_master, :type => :boolean,
      :desc => "Force a deploy even if the master is in a bad state"
    method_option :migrate, :type => :string, :aliases => %w(-m),
      :lazy_default => true,
      :desc => "Run migrations via [MIGRATE], defaults to '#{EY::DeployConfig::Migrate::DEFAULT}'; use --no-migrate to avoid running migrations"
    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Environment in which to deploy this application"
    method_option :ref, :type => :string, :aliases => %w(-r --branch --tag),
      :desc => "Git ref to deploy. May be a branch, a tag, or a SHA. Use -R to deploy a different ref if a default is set."
    method_option :force_ref, :type => :string, :aliases => %w(--ignore-default-branch -R),
      :lazy_default => true,
      :desc => "Force a deploy of the specified git ref even if a default is set in ey.yml."
    method_option :app, :type => :string, :aliases => %w(-a),
      :desc => "Name of the application to deploy"
    method_option :account, :type => :string, :aliases => %w(-c),
      :desc => "Name of the account in which the environment can be found"
    method_option :verbose, :type => :boolean, :aliases => %w(-v),
      :desc => "Be verbose"
    method_option :extra_deploy_hook_options, :type => :hash, :default => {},
      :desc => "Additional options to be made available in deploy hooks (in the 'config' hash)"
    def deploy
      EY.ui.info "Loading application data from EY Cloud..."

      app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
      app_env.environment.ignore_bad_master = options[:ignore_bad_master]

      env_config    = EY.config.environment_config(app_env.environment_name)
      deploy_config = EY::DeployConfig.new(options, env_config, repo, EY.ui)

      deployment = app_env.new_deployment({
        :ref             => deploy_config.ref,
        :migrate         => deploy_config.migrate,
        :migrate_command => deploy_config.migrate_command,
        :extra_config    => deploy_config.extra_config,
        :verbose         => deploy_config.verbose,
      })

      EY.ui.info  "Beginning deploy..."
      deployment.start
      EY.ui.show_deployment(deployment)

      begin
        deployment.deploy
      rescue Interrupt
        EY.ui.warn "Interrupted."
        EY.ui.warn "Recording canceled deployment and exiting..."
        EY.ui.warn "WARNING: Interrupting again may result in a never-finished deployment in the deployment history on EY Cloud."
        raise
      rescue StandardError => e
        EY.ui.info "Error encountered during deploy."
        raise
      ensure
        if deployment.finished?
          EY.ui.info "#{deployment.successful? ? 'Successful' : 'Failed'} deployment recorded on EY Cloud"
        end
      end

      if deployment.successful?
        EY.ui.info "Deploy complete"
        EY.ui.info "Now you can run `ey launch' to open the application in a browser."
      else
        raise EY::Error, "Deploy failed"
      end
    end

    desc "status", "Show the deployment status of the app"
    long_desc <<-DESC
      Show the current status of most recent deployment of the specified
      application and environment.
    DESC
    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Environment where the application is deployed"
    method_option :app, :type => :string, :aliases => %w(-a),
      :desc => "Name of the application"
    method_option :account, :type => :string, :aliases => %w(-c),
      :desc => "Name of the account in which the application can be found"
    def status
      app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
      deployment = app_env.last_deployment
      if deployment
        EY.ui.say "# Status of last deployment of #{app_env.to_hierarchy_str}:"
        EY.ui.say "#"
        EY.ui.show_deployment(deployment)
        EY.ui.say "#"
        EY.ui.deployment_result(deployment)
      else
        raise EY::Error, "Application #{app_env.app.name} has not been deployed on #{app_env.environment.name}."
      end
    end

    desc "environments [--all]", "List environments for this app; use --all to list all environments."
    long_desc <<-DESC
      By default, environments for this app are displayed. The --all option will
      display all environments, including those for this app.
    DESC

    method_option :all, :type => :boolean, :aliases => %(-a)
    method_option :simple, :type => :boolean, :aliases => %(-s)
    def environments
      if options[:all] && options[:simple]
        # just put each env
        puts api.environments.map {|env| env.name}
      elsif options[:all]
        EY.ui.print_envs(api.apps, EY.config.default_environment, options[:simple])
      else
        repo.fail_on_no_remotes!
        apps = api.apps.find_all {|a| repo.has_remote?(a.repository_uri) }

        if apps.size > 1
          message = "This git repo matches multiple Applications in EY Cloud:\n"
          apps.each { |app| message << "\t#{app.name}\n" }
          message << "The following environments contain those applications:\n\n"
          EY.ui.warn(message)
        elsif apps.empty?
          EY.ui.warn(EY::CloudClient::NoAppError.new(repo, EY.config.endpoint).message + "\nUse #{self.class.send(:banner_base)} environments --all to see all environments.")
        end

        EY.ui.print_envs(apps, EY.config.default_environment, options[:simple])
      end
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
    method_option :account, :type => :string, :aliases => %w(-c),
      :desc => "Name of the account in which the environment can be found"
    def rebuild
      environment = fetch_environment(options[:environment], options[:account])
      EY.ui.debug("Rebuilding #{environment.name}")
      environment.rebuild
    end
    map "update" => :rebuild

    desc "rollback [--environment ENVIRONMENT]", "Rollback to the previous deploy."
    long_desc <<-DESC
      Uses code from previous deploy in the "/data/APP_NAME/releases" directory on
      remote server(s) to restart application servers.
    DESC

    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Environment in which to roll back the application"
    method_option :app, :type => :string, :aliases => %w(-a),
      :desc => "Name of the application to roll back"
    method_option :account, :type => :string, :aliases => %w(-c),
      :desc => "Name of the account in which the environment can be found"
    method_option :verbose, :type => :boolean, :aliases => %w(-v),
      :desc => "Be verbose"
    method_option :extra_deploy_hook_options, :type => :hash, :default => {},
      :desc => "Additional options to be made available in deploy hooks (in the 'config' hash)"
    def rollback
      app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
      env_config    = EY.config.environment_config(app_env.environment_name)
      deploy_config = EY::DeployConfig.new(options, env_config, repo, EY.ui)

      EY.ui.info("Rolling back #{app_env.to_hierarchy_str}")
      if app_env.rollback(deploy_config.extra_config, deploy_config.verbose)
        EY.ui.info "Rollback complete"
      else
        raise EY::Error, "Rollback failed"
      end
    end

    desc "ssh [COMMAND] [--all] [--environment ENVIRONMENT]", "Open an ssh session to the master app server, or run a command."
    long_desc <<-DESC
      If a command is supplied, it will be run, otherwise a session will be
      opened. The application master is used for environments with clusters.
      Option --all requires a command to be supplied and runs it on all servers.

      Note: this command is a bit picky about its ordering. To run a command with arguments on
      all servers, like "rm -f /some/file", you need to order it like so:

      $ #{banner_base} ssh "rm -f /some/file" -e my-environment --all
    DESC
    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Environment to ssh into"
    method_option :account, :type => :string, :aliases => %w(-c),
      :desc => "Name of the account in which the environment can be found"
    method_option :all, :type => :boolean, :aliases => %(-a),
      :desc => "Run command on all servers"
    method_option :app_servers, :type => :boolean,
      :desc => "Run command on all application servers"
    method_option :db_servers, :type => :boolean,
      :desc => "Run command on the database servers"
    method_option :db_master, :type => :boolean,
      :desc => "Run command on the master database server"
    method_option :db_slaves, :type => :boolean,
      :desc => "Run command on the slave database servers"
    method_option :utilities, :type => :array, :lazy_default => true,
      :desc => "Run command on the utility servers with the given names. If no names are given, run on all utility servers."

    def ssh(cmd=nil)
      environment = fetch_environment(options[:environment], options[:account])
      hosts = ssh_hosts(options, environment)

      raise NoCommandError.new if cmd.nil? and hosts.size != 1

      exits = hosts.map do |host|
        system Escape.shell_command(['ssh', "#{environment.username}@#{host}", cmd].compact)
        $?.exitstatus
      end
      exit exits.detect {|status| !status.zero?} || 0
    end

    no_tasks do
      def ssh_host_filter(opts)
        return lambda {|instance| true }                                                if opts[:all]
        return lambda {|instance| %w(solo app app_master    ).include?(instance.role) } if opts[:app_servers]
        return lambda {|instance| %w(solo db_master db_slave).include?(instance.role) } if opts[:db_servers ]
        return lambda {|instance| %w(solo db_master         ).include?(instance.role) } if opts[:db_master  ]
        return lambda {|instance| %w(db_slave               ).include?(instance.role) } if opts[:db_slaves  ]
        return lambda {|instance| %w(util).include?(instance.role) && opts[:utilities].include?(instance.name) } if opts[:utilities]
        return lambda {|instance| %w(solo app_master        ).include?(instance.role) }
      end

      def ssh_hosts(opts, environment)
        if opts[:utilities] and not opts[:utilities].respond_to?(:include?)
          includes_everything = []
          class << includes_everything
            def include?(*) true end
          end
          filter = ssh_host_filter(opts.merge(:utilities => includes_everything))
        else
          filter = ssh_host_filter(opts)
        end

        instances = environment.instances.select {|instance| filter[instance] }
        raise NoInstancesError.new(environment.name) if instances.empty?
        return instances.map { |instance| instance.public_hostname }
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
    method_option :account, :type => :string, :aliases => %w(-c),
      :desc => "Name of the account in which the environment can be found"
    def logs
      environment = fetch_environment(options[:environment], options[:account])
      environment.logs.each do |log|
        EY.ui.info log.instance_name

        if log.main
          EY.ui.info "Main logs for #{environment.name}:"
          EY.ui.say  log.main
        end

        if log.custom
          EY.ui.info "Custom logs for #{environment.name}:"
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
        deploy_cmds = %w(deploy environments logs rebuild rollback status)
        deploy_cmds.map! do |name|
          list.find{|task| task[0] =~ /^#{base} #{name}/ }
        end
        list -= deploy_cmds

        EY.ui.print_help(deploy_cmds)
        EY.ui.say

        self.class.subcommands.each do |name|
          klass = self.class.subcommand_class_for(name)
          list.reject!{|cmd| cmd[0] =~ /^#{base} #{name}/}
          EY.ui.say "#{name.capitalize} commands:"
          tasks = klass.printable_tasks.reject{|t| t[0] =~ /help$/ }
          EY.ui.print_help(tasks)
          EY.ui.say
        end

        %w(help version).each{|n| list.reject!{|c| c[0] =~ /^#{base} #{n}/ } }
        if list.any?
          EY.ui.say "Other commands:"
          EY.ui.print_help(list)
          EY.ui.say
        end

        self.class.send(:class_options_help, shell)
        EY.ui.say "See '#{base} help COMMAND' for more information on a specific command."
      elsif klass = self.class.subcommand_class_for(cmds.first)
        klass.new.help(*cmds[1..-1])
      else
        super
      end
    end

    desc "launch [--environment ENVIRONMENT] [--account ACCOUNT]", "Open application in browser."
    method_option :environment, :type => :string, :aliases => %w(-e),
      :desc => "Name of the environment"
    method_option :account, :type => :string, :aliases => %w(-c),
      :desc => "Name of the account in which the environment can be found"
    def launch
      environment = fetch_environment(options[:environment], options[:account])
      environment.launch
    end

    desc "whoami", "Who am I logged in as?"
    def whoami
      current_user = api.current_user
      EY.ui.say "#{current_user.name} (#{current_user.email})"
    end

    desc "login", "Log in and verify access to EY Cloud."
    def login
      whoami
    end

    desc "logout", "Remove the current API key from ~/.eyrc or env variable $EYRC"
    def logout
      eyrc = EYRC.load
      if eyrc.delete_api_token
        EY.ui.say "API token removed: #{eyrc.path}"
        EY.ui.say "Run any other command to login again."
      else
        EY.ui.say "Already logged out. Run any other command to login again."
      end
    end

  end # CLI
end # EY
