require 'engineyard'
require 'engineyard/error'
require 'engineyard/thor'
require 'engineyard/deploy_config'
require 'engineyard/serverside_runner'
require 'launchy'
require 'fileutils'

module EY
  class CLI < EY::Thor
    require 'engineyard/cli/recipes'
    require 'engineyard/cli/web'
    require 'engineyard/cli/api'
    require 'engineyard/cli/ui'
    require 'engineyard/error'
    require 'engineyard-cloud-client/errors'

    include Thor::Actions

    def self.start(given_args=ARGV, config={})
      Thor::Base.shell = EY::CLI::UI
      ui = EY::CLI::UI.new
      super(given_args, {shell: ui}.merge(config))
    rescue Thor::Error, EY::Error, EY::CloudClient::Error => e
      ui.print_exception(e)
      raise
    rescue Interrupt => e
      puts
      ui.print_exception(e)
      ui.say("Quitting...")
      raise
    rescue SystemExit, Errno::EPIPE
      # don't print a message for safe exits
      raise
    rescue Exception => e
      ui.print_exception(e)
      raise
    end

    class_option :api_token, type: :string, desc: "Use API_TOKEN to authenticate this command"
    class_option :serverside_version, type: :string, desc: "Please use with care! Override deploy system version (same as ENV variable ENGINEYARD_SERVERSIDE_VERSION)"
    class_option :quiet, aliases: %w[-q], type: :boolean, desc: "Quieter CLI output."

    desc "init",
      "Initialize the current directory with an ey.yml configuration file."
    long_desc <<-DESC
      Initialize the current directory with an ey.yml configuration file.

      Please read the generated file and make adjustments.
      Many applications will need only the default behavior.
      For reference, many available options are explained in the generated file.

      IMPORTANT: THE GENERATED FILE '#{EY::Config.pathname_for_write}'
      MUST BE COMMITTED TO YOUR REPOSITORY OR OPTIONS WILL NOT BE LOADED.
    DESC
    method_option :path, type: :string, aliases: %w(-p),
      desc: "Path for ey.yml (supported paths: #{EY::Config::CONFIG_FILES.join(', ')})"
    def init
      unless EY::Repo.exist?
        raise EY::Error, "Working directory is not a repository. Aborting."
      end

      path = Pathname.new(options['path'] || EY::Config.pathname_for_write)

      existing = {}
      if path.exist?
        ui.warn "Reinitializing existing file: #{path}"
        existing = EY::Config.load_config
      end

      template = EY::Templates::EyYml.new(existing)
      template.write(path)

      ui.info <<-GIT

Configuration generated: #{path}
Go look at it, then add it to your repository!

\tgit add #{path}
\tgit commit -m "Add generated #{path} from ey init"

      GIT
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
    method_option :ignore_bad_master, type: :boolean, aliases: %w(--ignore-bad-bridge),
      desc: "Force a deploy even if the master is in a bad state"
    method_option :migrate, type: :string, aliases: %w(-m),
      lazy_default: true,
      desc: "Run migrations via [MIGRATE]; use --no-migrate to avoid running migrations"
    method_option :ref, type: :string, aliases: %w(-r --branch --tag),
      required: true, default: '',
      desc: "Git ref to deploy. May be a branch, a tag, or a SHA. Use -R to deploy a different ref if a default is set."
    method_option :force_ref, type: :string, aliases: %w(--ignore-default-branch -R),
      lazy_default: true,
      desc: "Force a deploy of the specified git ref even if a default is set in ey.yml."
    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: false,
      desc: "Environment in which to deploy this application"
    method_option :app, type: :string, aliases: %w(-a),
      required: true, default: '',
      desc: "Name of the application to deploy"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Name of the account in which the environment can be found"
    method_option :verbose, type: :boolean, aliases: %w(-v),
      desc: "Be verbose"
    method_option :config, type: :hash, default: {}, aliases: %w(--extra-deploy-hook-options),
      desc: "Hash made available in deploy hooks (in the 'config' hash), can also override some ey.yml settings."
    def deploy
      app_env = fetch_app_environment(options[:app], options[:environment], options[:account])

      env_config    = config.environment_config(app_env.environment_name)
      deploy_config = EY::DeployConfig.new(options, env_config, repo, ui)

      deployment = app_env.new_deployment({
        ref:                deploy_config.ref,
        migrate:            deploy_config.migrate,
        migrate_command:    deploy_config.migrate_command,
        extra_config:       deploy_config.extra_config,
        serverside_version: serverside_version,
      })

      runner = serverside_runner(app_env, deploy_config.verbose, deployment.serverside_version, options[:ignore_bad_master])

      out = EY::CLI::UI::Tee.new(ui.out, deployment.output)
      err = EY::CLI::UI::Tee.new(ui.err, deployment.output)

      ui.info  "Beginning deploy...", :green
      begin
        deployment.start
      rescue
        ui.error "Error encountered before deploy. Deploy not started."
        raise
      end

      begin
        ui.show_deployment(deployment)
        out << "Deploy initiated.\n"

        runner.deploy do |args|
          args.config  = deployment.config          if deployment.config
          if deployment.migrate
            args.migrate = deployment.migrate_command
          else
            args.migrate = false
          end
          args.ref     = deployment.resolved_ref
        end
        deployment.successful = runner.call(out, err)
      rescue Interrupt
        Signal.trap(:INT) { # The fingers you have used to dial are too fat...
          ui.info "\nRun `ey timeout-deploy` to mark an unfinished deployment as failed."
          exit 1
        }
        err << "Interrupted. Deployment halted.\n"
        ui.warn <<-WARN
Recording interruption of this unfinished deployment in Engine Yard Cloud...

WARNING: Interrupting again may prevent Engine Yard Cloud from recording this
         failed deployment. Unfinished deployments can block future deploys.
        WARN
        raise
      rescue StandardError => e
        deployment.err << "Error encountered during deploy.\n#{e.class} #{e}\n"
        ui.print_exception(e)
        raise
      ensure
        ui.info "Saving log... ", :green
        deployment.finished

        if deployment.successful?
          ui.info "Successful deployment recorded on Engine Yard Cloud.", :green
          ui.info "Run `ey launch` to open the application in a browser."
        else
          ui.info "Failed deployment recorded on Engine Yard Cloud", :green
          raise EY::Error, "Deploy failed"
        end
      end
    end

    desc "timeout-deploy [--environment ENVIRONMENT]",
      "Fail a stuck unfinished deployment."
    long_desc <<-DESC
      NOTICE: Timing out a deploy does not stop currently running deploy
      processes.

      This command must be run in the current directory containing the app.
      The latest running deployment will be marked as failed, allowing a
      new deployment to be run. It is possible to mark a potentially successful
      deployment as failed. Only run this when a deployment is known to be
      wrongly unfinished/stuck and when further deployments are blocked.
    DESC
    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: false,
      desc: "Environment in which to deploy this application"
    method_option :app, type: :string, aliases: %w(-a),
      required: true, default: '',
      desc: "Name of the application to deploy"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Name of the account in which the environment can be found"
    def timeout_deploy
      app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
      deployment = app_env.last_deployment
      if deployment && !deployment.finished?
        begin
          ui.info  "Marking last deployment failed...", :green
          deployment.timeout
          ui.deployment_status(deployment)
        rescue EY::CloudClient::RequestFailed => e
          ui.error "Error encountered attempting to timeout previous deployment."
          raise
        end
      else
        raise EY::Error, "No unfinished deployment was found for #{app_env.hierarchy_name}."
      end
    end

    desc "status", "Show the deployment status of the app"
    long_desc <<-DESC
      Show the current status of most recent deployment of the specified
      application and environment.
    DESC
    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: '',
      desc: "Environment where the application is deployed"
    method_option :app, type: :string, aliases: %w(-a),
      required: true, default: '',
      desc: "Name of the application"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Name of the account in which the application can be found"
    def status
      app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
      deployment = app_env.last_deployment
      if deployment
        ui.deployment_status(deployment)
      else
        raise EY::Error, "Application #{app_env.app.name} has not been deployed on #{app_env.environment.name}."
      end
    end

    desc "environments [--all]", "List environments for this app; use --all to list all environments."
    long_desc <<-DESC
      By default, environments for this app are displayed. The --all option will
      display all environments, including those for this app.
    DESC

    method_option :all, type: :boolean, aliases: %(-A),
      desc: "Show all environments (ignores --app, --account, and --environment arguments)"
    method_option :simple, type: :boolean, aliases: %(-s),
      desc: "Display one environment per line with no extra output"
    method_option :app, type: :string, aliases: %w(-a),
      required: true, default: '',
      desc: "Show environments for this application"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Show environments in this account"
    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: '',
      desc: "Show environments matching environment name"
    def environments
      if options[:all] && options[:simple]
        ui.print_simple_envs api.environments
      elsif options[:all]
        ui.print_envs api.apps
      else
        remotes = nil
        if options[:app] == ''
          repo.fail_on_no_remotes!
          remotes = repo.remotes
        end

        resolver = api.resolve_app_environments({
          account_name:     options[:account],
          app_name:         options[:app],
          environment_name: options[:environment],
          remotes:          remotes,
        })

        resolver.no_matches do |errors|
          messages = errors
          messages << "Use #{self.class.send(:banner_base)} environments --all to see all environments."
          raise EY::NoMatchesError.new(messages.join("\n"))
        end

        apps = resolver.matches.map { |app_env| app_env.app }.uniq

        if options[:simple]
          if apps.size > 1
            message = "# This app matches multiple Applications in Engine Yard Cloud:\n"
            apps.each { |app| message << "#\t#{app.name}\n" }
            message << "# The following environments contain those applications:\n\n"
            ui.warn(message)
          end
          ui.print_simple_envs(apps.map{ |app| app.environments }.flatten)
        else
          ui.print_envs(apps, config.default_environment)
        end
      end
    end
    map "envs" => :environments

    desc "servers", "List servers for an environment."
    long_desc <<-DESC
      Display a list of all servers on an environment.
      Specify -s (--simple) to make parsing the output easier
      or -uS (--user --host) to output bash loop friendly "user@hostname"
    DESC

    method_option :simple, type: :boolean, aliases: %(-s),
      desc: "Display all information in a simplified format without extra text or column alignment"
    method_option :host, type: :boolean, aliases: %(-S),
      desc: "Display only hostnames, one per newline (use options -uS (--user --host) for user@hostname)"
    method_option :user, type: :boolean, aliases: %w(-u),
      desc: "Include the ssh username in front of the hostname for easy SSH scripting"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Find environment in this account"
    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: '',
      desc: "Show servers in environment matching environment name"
    method_option :all, type: :boolean, aliases: %(-A),
      desc: "Show all servers (for compatibility only, this is the default for this command)"
    method_option :app_master, type: :boolean,
      desc: "Show only app master server"
    method_option :app_servers, type: :boolean, aliases: %w(--app),
      desc: "Show only application servers"
    method_option :db_servers, type: :boolean, aliases: %w(--db),
      desc: "Show only database servers"
    method_option :db_master, type: :boolean,
      desc: "Show only the master database server"
    method_option :db_slaves, type: :boolean,
      desc: "Show only the slave database servers"
    method_option :utilities, type: :array, lazy_default: true, aliases: %w(--util),
      desc: "Show only utility servers or only utility servers with the given names"
    def servers
      if options[:environment] == '' && options[:account] == ''
        repo.fail_on_no_remotes!
      end

      environment = nil
      ui.mute_if(options[:simple] || options[:host]) do
        environment = fetch_environment(options[:environment], options[:account])
      end

      username = options[:user] && environment.username

      servers = filter_servers(environment, options, default: {all: true})

      if options[:host]
        ui.print_hostnames(servers, username)
      elsif options[:simple]
        ui.print_simple_servers(servers, username)
      else
        ui.print_servers(servers, environment.hierarchy_name, username)
      end
    end

    desc "rebuild [--environment ENVIRONMENT]", "Rebuild specified environment."
    long_desc <<-DESC
      Engine Yard's main configuration run occurs on all servers. Mainly used to fix
      failed configuration of new or existing servers, or to update servers to latest
      Engine Yard stack (e.g. to apply an Engine Yard supplied security
      patch).

      Note that uploaded recipes are also run after the main configuration run has
      successfully completed.
    DESC

    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: '',
      desc: "Environment to rebuild"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Name of the account in which the environment can be found"
    def rebuild
      environment = fetch_environment(options[:environment], options[:account])
      ui.info "Updating instances on #{environment.hierarchy_name}"
      environment.rebuild
    end
    map "update" => :rebuild

    desc "rollback [--environment ENVIRONMENT]", "Rollback to the previous deploy."
    long_desc <<-DESC
      Uses code from previous deploy in the "/data/APP_NAME/releases" directory on
      remote server(s) to restart application servers.
    DESC

    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: '',
      desc: "Environment in which to roll back the application"
    method_option :app, type: :string, aliases: %w(-a),
      required: true, default: '',
      desc: "Name of the application to roll back"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Name of the account in which the environment can be found"
    method_option :verbose, type: :boolean, aliases: %w(-v),
      desc: "Be verbose"
    method_option :config, type: :hash, default: {}, aliases: %w(--extra-deploy-hook-options),
      desc: "Hash made available in deploy hooks (in the 'config' hash), can also override some ey.yml settings."
    def rollback
      app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
      env_config    = config.environment_config(app_env.environment_name)
      deploy_config = EY::DeployConfig.new(options, env_config, repo, ui)

      ui.info "Rolling back #{app_env.hierarchy_name}"

      runner = serverside_runner(app_env, deploy_config.verbose)
      runner.rollback do |args|
        args.config = {'deployed_by' => api.current_user.name, 'input_ref' => 'N/A'}.merge(deploy_config.extra_config || {})
      end

      if runner.call(ui.out, ui.err)
        ui.info "Rollback complete"
      else
        raise EY::Error, "Rollback failed"
      end
    end

    desc "ssh [COMMAND] [--all] [--environment ENVIRONMENT]", "Open an ssh session to the master app server, or run a command."
    long_desc <<-DESC
      If a command is supplied, it will be run, otherwise a session will be
      opened. The bridge server (app master) is used for environments with multiple instances.

      Option --all requires a command to be supplied and runs it on all servers or
      pass --each to connect to each server one after another.

      Note: this command is a bit picky about its ordering. To run a command with arguments on
      all servers, like "rm -f /some/file", you need to order it like so:

      $ #{banner_base} ssh "rm -f /some/file" -e my-environment --all
    DESC
    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: '',
      desc: "Environment to ssh into"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Name of the account in which the environment can be found"
    method_option :all, type: :boolean, aliases: %(-A),
      desc: "Run command on all servers"
    method_option :app_servers, type: :boolean,
      desc: "Run command on all application servers"
    method_option :db_servers, type: :boolean,
      desc: "Run command on the database servers"
    method_option :db_master, type: :boolean,
      desc: "Run command on the master database server"
    method_option :db_slaves, type: :boolean,
      desc: "Run command on the slave database servers"
    method_option :utilities, type: :array, lazy_default: true,
      desc: "Run command on the utility servers with the given names. If no names are given, run on all utility servers."
    method_option :shell, type: :string, default: 'bash', aliases: %w(-s),
      desc: "Run command in a shell other than bash. Use --no-shell to run the command without a shell."
    method_option :pty, type: :boolean, default: false, aliases: %w(-t),
      desc: "If a command is given, run in a pty. Required for interactive commands like sudo."
    method_option :bind_address, type: :string, aliases: %w(-L),
      desc: "When a command is not given, pass -L to the ssh command."
    method_option :each, type: :boolean, default: false,
      desc: "If no command is given, connect to multiple servers each one after another, instead of exiting with an error."

    def ssh(cmd=nil)
      environment = fetch_environment(options[:environment], options[:account])
      instances = filter_servers(environment, options, default: {app_master: true})
      user = environment.username
      ssh_opts = []

      if cmd
        if options[:shell]
          cmd = Escape.shell_command([options[:shell],'-lc',cmd])
        end

        if options[:pty]
          ssh_opts = ["-t"]
        elsif cmd =~ /sudo/
          ui.warn "sudo commands often need a tty to run correctly. Use -t option to spawn a tty."
        end
      else
        if instances.size != 1 && options[:each] == false
          raise NoCommandError.new
        end

        if options[:bind_address]
          ssh_opts = ["-L", options[:bind_address]]
        end
      end

      ssh_cmd = ["ssh"]
      ssh_cmd += ssh_opts

      trap(:INT) { abort "Aborting..." }

      exits = []
      instances.each do |instance|
        host = instance.public_hostname
        name = instance.name ? "#{instance.role} (#{instance.name})" : instance.role
        ui.info "\nConnecting to #{name} #{host}..."
        unless cmd
          ui.info "Ctrl + C to abort"
          sleep 1.3
        end
        sshcmd = Escape.shell_command((ssh_cmd + ["#{user}@#{host}"] + [cmd]).compact)
        ui.debug "$ #{sshcmd}"
        system sshcmd
        exits << $?.exitstatus
      end

      exit exits.detect {|status| status != 0 } || 0
    end

    no_tasks do
      OPT_TO_ROLES = {
        all:         %w[all],
        app_master:  %w[solo app_master],
        app_servers: %w[solo app app_master],
        db_servers:  %w[solo db_master db_slave],
        db_master:   %w[solo db_master],
        db_slaves:   %w[db_slave],
        utilities:   %w[util],
      }

      def filter_servers(environment, cli_opts, filter_opts)
        if (cli_opts.keys.map(&:to_sym) & OPT_TO_ROLES.keys).any?
          options = cli_opts.dup
        else
          options = filter_opts[:default].dup
        end

        options.keep_if {|k,v| OPT_TO_ROLES.has_key?(k.to_sym) }

        if options[:all]
          instances = environment.instances
        else
          roles = {}
          options.each do |cli_opt,cli_val|
            if cli_val && OPT_TO_ROLES.has_key?(cli_opt.to_sym)
              OPT_TO_ROLES[cli_opt.to_sym].each do |role|
                roles[role] = cli_val # val is true or an array of strings
              end
            end
          end
          instances = environment.select_instances(roles)
        end

        if instances.empty?
          raise NoInstancesError.new(environment.name)
        end

        return instances
      end
    end

    desc "logs [--environment ENVIRONMENT]", "Retrieve the latest logs for an environment."
    long_desc <<-DESC
      Displays Engine Yard configuration logs for all servers in the environment. If
      recipes were uploaded to the environment & run, their logs will also be
      displayed beneath the main configuration logs.
    DESC
    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: '',
      desc: "Environment with the interesting logs"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Name of the account in which the environment can be found"
    def logs
      environment = fetch_environment(options[:environment], options[:account])
      environment.logs.each do |log|
        ui.say "Instance: #{log.instance_name}"

        if log.main
          ui.say "Main logs for #{environment.name}:", :green
          ui.say  log.main
        end

        if log.custom
          ui.say "Custom logs for #{environment.name}:", :green
          ui.say  log.custom
        end
      end
    end

    desc "recipes", "Commands related to chef recipes."
    subcommand "recipes", EY::CLI::Recipes

    desc "web", "Commands related to maintenance pages."
    subcommand "web", EY::CLI::Web

    desc "version", "Print version number."
    def version
      ui.say %{engineyard version #{EY::VERSION}}
    end
    map ["-v", "--version"] => :version

    desc "help [COMMAND]", "Describe all commands or one specific command."
    def help(*cmds)
      if cmds.empty?
        base = self.class.send(:banner_base)
        list = self.class.printable_tasks

        ui.say "Usage:"
        ui.say "  #{base} [--help] [--version] COMMAND [ARGS]"
        ui.say

        ui.say "Deploy commands:"
        deploy_cmds = %w(deploy environments logs rebuild rollback status)
        deploy_cmds.map! do |name|
          list.find{|task| task[0] =~ /^#{base} #{name}/ }
        end
        list -= deploy_cmds

        ui.print_help(deploy_cmds)
        ui.say

        self.class.subcommands.each do |name|
          klass = self.class.subcommand_class_for(name)
          list.reject!{|cmd| cmd[0] =~ /^#{base} #{name}/}
          ui.say "#{name.capitalize} commands:"
          tasks = klass.printable_tasks.reject{|t| t[0] =~ /help$/ }
          ui.print_help(tasks)
          ui.say
        end

        %w(help version).each{|n| list.reject!{|c| c[0] =~ /^#{base} #{n}/ } }
        if list.any?
          ui.say "Other commands:"
          ui.print_help(list)
          ui.say
        end

        self.class.send(:class_options_help, shell)
        ui.say "See '#{base} help COMMAND' for more information on a specific command."
      elsif klass = self.class.subcommand_class_for(cmds.first)
        klass.new.help(*cmds[1..-1])
      else
        super
      end
    end

    desc "launch [--app APP] [--environment ENVIRONMENT] [--account ACCOUNT]", "Open application in browser."
    method_option :environment, type: :string, aliases: %w(-e),
      required: true, default: '',
      desc: "Environment where the application is deployed"
    method_option :app, type: :string, aliases: %w(-a),
      required: true, default: '',
      desc: "Name of the application"
    method_option :account, type: :string, aliases: %w(-c),
      required: true, default: '',
      desc: "Name of the account in which the application can be found"
    def launch
      app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
      Launchy.open(app_env.uri)
    end

    desc "whoami", "Who am I logged in as?"
    def whoami
      current_user = api.current_user
      ui.say "#{current_user.name} (#{current_user.email})"
    end

    desc "login", "Log in and verify access to Engine Yard Cloud."
    long_desc <<-DESC
      You may run this command to log in to EY Cloud without performing
      any other action.

      Once you are logged in, a file will be stored at ~/.eyrc with your
      API token. You may override the location of this file using the
      $EYRC environment variable.

      Instead of logging in, you may specify a token on the command line
      with --api-token or using the $ENGINEYARD_API_TOKEN environment
      variable.
    DESC
    def login
      whoami
    end

    desc "logout", "Remove the current API key from ~/.eyrc or env variable $EYRC"
    def logout
      eyrc = EYRC.load
      if eyrc.delete_api_token
        ui.info "API token removed: #{eyrc.path}"
        ui.info "Run any other command to login again."
      else
        ui.info "Already logged out. Run any other command to login again."
      end
    end

  end # CLI
end # EY
