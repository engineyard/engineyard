$LOAD_PATH.unshift File.expand_path("../vendor", __FILE__)
require 'thor'

module EY
  class Thor < ::Thor
    def self.start(original_args=ARGV, config={})
      @@original_args = original_args
      super
    end

    no_tasks do
      def self.subcommands
        @@subcommands ||= {}
      end

      def self.subcommand(subcommand, subcommand_class)
        subcommand = subcommand.to_s
        subcommands[subcommand] = subcommand_class
        subcommand_class.subcommand_help subcommand
        define_method(subcommand) { |*_| subcommand_class.start(subcommand_args) }
      end

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

      def subcommand_args
        @@original_args[1..-1]
      end

      def self.banner_base
        "ey"
      end

      def self.banner(task, task_help = false)
        scmd = EY::Thor.subcommands.invert[self]
        task = (task_help ? task.formatted_usage(self, false) : task.name)
        [banner_base, scmd, task].compact.join(" ")
      end
    end

    protected

    def self.handle_no_task_error(task)
      if self.banner_base == "thor"
        raise UndefinedTaskError, "Could not find command #{task.inspect} in #{namespace.inspect} namespace."
      else
        raise UndefinedTaskError, "Could not find command #{task.inspect}."
      end
    end

    def self.exit_on_failure?
      true
    end

    def api
      @api ||= EY::CLI::API.new
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def loudly_check_eysd(environment)
      environment.ensure_eysd_present do |action|
        case action
        when :installing
          EY.ui.warn "Instance does not have server-side component installed"
          EY.ui.info "Installing server-side component..."
        when :upgrading
          EY.ui.info "Upgrading server-side component..."
        else
          # nothing slow is happening, so there's nothing to say
        end
      end
    end

    # if an app is supplied, it is used as a constraint for implied environment lookup
    def fetch_environment(env_name, app = nil)
      env_name ||= EY.config.default_environment
      if env_name
        (app || api).environments.match_one!(env_name)
      else
        (app || api.app_for_repo!(repo)).sole_environment!
      end
    end

    def get_apps(all_apps = false)
      if all_apps
        api.apps
      else
        [api.app_for_repo(repo)].compact
      end
    end
  end
end
