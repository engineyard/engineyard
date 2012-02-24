require 'thor'

module EY
  module UtilityMethods
    protected
    def api
      @api ||= EY::CLI::API.new(config.endpoint, ui)
    end

    def config
      @config ||= EY::Config.new
    end

    def ui
      @ui ||= load_ui
    end

    def load_ui
      Thor::Base.shell = EY::CLI::UI
      EY::CLI::UI.new
    end

    def in_repo?
      EY::Repo.exist?
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def serverside_runner(app_env, verbose)
      ServersideRunner.new(app_env.environment.bridge!.hostname, app_env.app, app_env.environment, verbose)
    end

    def fetch_environment(environment_name, account_name)
      environment_name ||= config.default_environment
      remotes = repo.remotes if in_repo?
      constraints = {
        :environment_name => environment_name,
        :account_name     => account_name,
        :remotes          => remotes,
      }

      resolver = api.resolve_environments(constraints)

      resolver.one_match { |match| return match  }

      resolver.no_matches do |errors, suggestions|
        raise EY::NoMatchesError.new(errors.join("\n"))
      end

      resolver.many_matches do |matches|
        if environment_name
          message = "Multiple environments possible, please be more specific:\n\n"
          matches.each do |env|
            message << "\t#{env.name.ljust(25)} # ey <command> --environment='#{env.name}' --account='#{env.account.name}'\n"
          end
          raise EY::MultipleMatchesError.new(message)
        else
          raise EY::AmbiguousEnvironmentGitUriError.new(matches)
        end
      end
    end

    def fetch_app_environment(app_name, environment_name, account_name)
      environment_name ||= config.default_environment
      remotes = repo.remotes if in_repo?
      constraints = {
        :app_name         => app_name,
        :environment_name => environment_name,
        :account_name     => account_name,
        :remotes          => remotes,
      }

      if constraints.all? { |k,v| v.nil? || v.empty? || v.to_s.empty? }
        raise EY::NoMatchesError.new <<-ERROR
Unable to find application without a git remote URI or app name.

Please specify --app app_name or add this application at #{config.endpoint}"
        ERROR
      end

      resolver = api.resolve_app_environments(constraints)

      resolver.one_match { |match| return match }
      resolver.no_matches do |errors, suggestions|
        message = ""
        if suggestions
          if apps = suggestions[:apps]
            message << "Matching Applications:\n"
            apps.each do |app|
              message << "\t#{app.account.name}/#{app.name}\n"
              #TODO describe command suggestions
              #app.environments.each do |env|
              #  message << "\t\t#{env.name} # ey <command> -e #{env.name} -a #{app.name}\n"
              #end
            end
          end

          if envs = suggestions[:environments]
            message << "Matching Environments:\n"
            envs.each do |env|
              message << "\t#{env.account.name}/#{env.name}\n"
            end
          end
        end

        raise EY::NoMatchesError.new([errors,message].join("\n").strip)
      end
      resolver.many_matches do |app_envs|
        raise EY::MultipleMatchesError.new(too_many_app_environments_error(app_envs))
      end
    end

      def too_many_app_environments_error(app_envs)
        message = "Multiple application environments possible, please be more specific:\n\n"

        app_envs.group_by do |app_env|
          [app_env.account_name, app_env.app_name]
        end.sort_by { |k,v| k.join }.each do |(account_name, app_name), grouped_app_envs|
          message << "\n"
          message << account_name << "/" << app_name << "\n"
          grouped_app_envs.map { |ae| ae.environment_name }.uniq.sort.each do |env_name|
            message << "\t#{env_name.ljust(25)}"
            message << " # ey <command> --account='#{account_name}' --app='#{app_name}' --environment='#{env_name}'\n"
          end
        end
        message
      end
  end # UtilityMethods

  class Thor < ::Thor
    include UtilityMethods

    check_unknown_options!

    no_tasks do
      def self.subcommand_help(cmd)
        desc "#{cmd} help [COMMAND]", "Describe all subcommands or one specific subcommand."
        class_eval <<-RUBY
          def help(*args)
            if args.empty?
              ui.say "usage: #{banner_base} #{cmd} COMMAND"
              ui.say
              subcommands = self.class.printable_tasks.sort_by{|s| s[0] }
              subcommands.reject!{|t| t[0] =~ /#{cmd} help$/}
              ui.print_help(subcommands)
              ui.say self.class.send(:class_options_help, ui)
              ui.say "See #{banner_base} #{cmd} help COMMAND" +
                " for more information on a specific subcommand." if args.empty?
            else
              super
            end
          end
        RUBY
      end

      def self.banner_base
        "ey"
      end

      def self.banner(task, task_help = false, subcommand = false)
        subcommand_banner = to_s.split(/::/).map{|s| s.downcase}[2..-1]
        subcommand_banner = if subcommand_banner.size > 0
                              subcommand_banner.join(' ')
                            else
                              nil
                            end

        task = (task_help ? task.formatted_usage(self, false, subcommand) : task.name)
        [banner_base, subcommand_banner, task].compact.join(" ")
      end

      def self.handle_no_task_error(task)
        raise UndefinedTaskError, "Could not find command #{task.inspect}."
      end

      def self.subcommand(name, klass)
        @@subcommand_class_for ||= {}
        @@subcommand_class_for[name] = klass
        super
      end

      def self.subcommand_class_for(name)
        @@subcommand_class_for ||= {}
        @@subcommand_class_for[name]
      end

    end

    protected

    def self.exit_on_failure?
      true
    end

  end

  # patch handle_no_method_error? to work with rubinius' error text.
  class ::Thor::Task
    def handle_no_method_error?(instance, error, caller)
      not_debugging?(instance) && (
        error.message =~ /^undefined method `#{name}' for #{Regexp.escape(instance.to_s)}$/ ||
        error.message =~ /undefined method `#{name}' on an instance of #{Regexp.escape(instance.class.name)}/
      )
    end
  end
end
