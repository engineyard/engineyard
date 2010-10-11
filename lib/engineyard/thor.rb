require 'thor'

module EY
  module UtilityMethods
    protected
    def api
      @api ||= EY::CLI::API.new
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def fetch_environment(environment_name, account_name=nil)
      environment_name ||= EY.config.default_environment
      options = {
        :environment_name => environment_name,
        :account_name => account_name
      }
      options.merge! :repo => repo if repo.exists?
      api.resolver.environment(options)
    end

    def fetch_app_and_environment(app_name = nil, environment_name = nil, account_name=nil)
      options = {
        :app_name => app_name,
        :environment_name => environment_name,
        :account_name => account_name
      }
      options.merge! :repo => repo if repo.exists?
      api.resolver.app_and_environment(options)
    end

    def get_apps(all_apps = false)
      if all_apps
        api.apps
      else
        api.apps_for_repo(repo)
      end
    end

  end # UtilityMethods

  class Thor < ::Thor
    include UtilityMethods

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
