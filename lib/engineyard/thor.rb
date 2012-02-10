require 'thor'

module EY
  module UtilityMethods
    protected
    def api
      @api ||= load_api
    end

    def load_api
      api = EY::CLI::API.new(EY.config.endpoint)
      api.current_user # check login and access to the api
      api
    rescue EY::CloudClient::InvalidCredentials
      EY::CLI::API.authenticate
      retry
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def fetch_environment(environment_name, account_name)
      environment_name ||= EY.config.default_environment
      remotes = repo.remotes if repo.exist?
      constraints = {
        :environment_name => environment_name,
        :account_name     => account_name,
        :remotes          => remotes,
      }

      resolver = api.resolve_environments(constraints)

      resolver.one_match { |match| return match  }

      resolver.no_matches do |errors, suggestions|
        raise EY::CloudClient::NoMatchesError.new(errors.join("\n"))
      end

      resolver.many_matches do |matches|
        if environment_name
          message = "Multiple environments possible, please be more specific:\n\n"
          matches.each do |env|
            message << "\t#{env.name.ljust(25)} # ey <command> --environment='#{env.name}' --account='#{env.account.name}'\n"
          end
          raise EY::CloudClient::MultipleMatchesError.new(message)
        else
          raise EY::CloudClient::AmbiguousEnvironmentGitUriError.new(matches)
        end
      end
    end

    def fetch_app_environment(app_name, environment_name, account_name)
      environment_name ||= EY.config.default_environment
      remotes = repo.remotes if repo.exist?
      constraints = {
        :app_name         => app_name,
        :environment_name => environment_name,
        :account_name     => account_name,
        :remotes          => remotes,
      }

      if constraints.all? { |k,v| v.nil? || v.empty? || v.to_s.empty? }
        raise EY::CloudClient::NoMatchesError.new <<-ERROR
Unable to find application without a git remote URI or app name.

Please specify --app app_name or add this application at #{EY::CloudClient.endpoint}"
        ERROR
      end

      resolver = api.resolve_app_environment(constraints)

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

        raise EY::CloudClient::NoMatchesError.new([errors,message].join("\n").strip)
      end
      resolver.many_matches do |app_envs|
        raise EY::CloudClient::MultipleMatchesError.new(too_many_app_environments_error(app_envs))
      end
    end

      def too_many_app_environments_error(app_envs)
        message = "Multiple application environments possible, please be more specific:\n\n"

        app_envs.group_by do |app_env|
          "#{app_env.account_name}/#{app_env.app_name}"
        end.each do |account_app_name, grouped_app_envs|
          message << account_app_name << "\n"
          grouped_app_envs.sort_by { |ae| ae.environment_name }.each do |app_env|
            message << "\t#{app_env.environment_name.ljust(25)}"
            message << " # ey <command> --account='#{app_env.account_name}' --app='#{app_env.app_name}' --environment='#{app_env.environment_name}'\n"
          end
        end
        EY::CloudClient::MultipleMatchesError.new(message)
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
              EY.ui.say "usage: #{banner_base} #{cmd} COMMAND"
              EY.ui.say
              subcommands = self.class.printable_tasks.sort_by{|s| s[0] }
              subcommands.reject!{|t| t[0] =~ /#{cmd} help$/}
              EY.ui.print_help(subcommands)
              EY.ui.say self.class.send(:class_options_help, EY.ui)
              EY.ui.say "See #{banner_base} #{cmd} help COMMAND" +
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
end
