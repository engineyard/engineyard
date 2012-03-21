require 'highline'

module EY
  class CLI
    class UI < Thor::Base.shell

      class Prompter
        def self.add_answer(arg)
          @answers ||= []
          @answers << arg
        end

        def self.questions
          @questions
        end

        def self.enable_mock!
          @questions = []
          @answers = []
          @mock = true
        end

        def self.highline
          @highline ||= HighLine.new($stdin)
        end

        def self.interactive?
          @mock || ($stdin && $stdin.tty?)
        end

        def self.ask(question, password = false, default = nil)
          if @mock
            @questions ||= []
            @questions << question
            answer = @answers.shift
            (answer == '' && default) ? default : answer
          else
            timeout_if_not_interactive do
              highline.ask(question) do |q|
                q.echo = "*"        if password
                q.default = default if default
              end
            end
          end
        end

        def self.agree(question, default)
          if @mock
            @questions ||= []
            @questions << question
            answer = @answers.shift
            answer == '' ? default : %w[y yes].include?(answer)
          else
            timeout_if_not_interactive do
              answer = highline.agree(question) {|q| q.default = default ? 'Y/n' : 'N/y' }
              case answer
              when 'Y/n' then true
              when 'N/y' then false
              else            answer
              end
            end
          end
        end

        def self.timeout_if_not_interactive(&block)
          if interactive?
            block.call
          else
            Timeout.timeout(5, &block)
          end
        end
      end

      def error(name, message = nil)
        $stdout = $stderr
        say_with_status(name, message, :red)
      ensure
        $stdout = STDOUT
      end

      def warn(name, message = nil)
        say_with_status(name, message, :yellow)
      end

      def info(name, message = nil)
        say_with_status(name, message, :green)
      end

      def debug(name, message = nil)
        if ENV["DEBUG"]
          name    = name.inspect    unless name.nil? or name.is_a?(String)
          message = message.inspect unless message.nil? or message.is_a?(String)
          say_with_status(name, message, :blue)
        end
      end

      def say_with_status(name, message=nil, color=nil)
        if message
          say_status name, message, color
        elsif name
          say name, color
        end
      end

      def interactive?
        Prompter.interactive?
      end

      def agree(message, default)
        Prompter.agree(message, default)
      end

      def ask(message, password = false, default = nil)
        Prompter.ask(message, password, default)
      rescue EOFError
        return ''
      end

      def print_envs(apps, default_env_name = nil, simple = false)
        if simple
          envs = apps.map{ |app| app.environments.to_a }
          puts envs.flatten.map{|env| env.name }.uniq
        else
          apps.each do |app|
            puts "#{app.name} (#{app.account.name})"
            if app.environments.any?
              app.environments.each do |env|
                short_name = env.shorten_name_for(app)

                icount = env.instances_count
                iname = (icount == 1) ? "instance" : "instances"

                default_text = env.name == default_env_name ? " [default]" : ""

                puts "  #{short_name}#{default_text} (#{icount} #{iname})"
              end
            else
              puts "  (This application is not in any environments; you can make one at #{EY.config.endpoint})"
            end

            puts ""
          end
        end
      end

      def show_deployment(dep)
        output = []
        output << ["Account",         dep.app.account.name]
        output << ["Application",     dep.app.name]
        output << ["Environment",     dep.environment.name]
        output << ["Input Ref",       dep.ref]
        output << ["Resolved Ref",    dep.resolved_ref]
        output << ["Commit",          dep.commit || '(not resolved)']
        output << ["Migrate",         dep.migrate]
        output << ["Migrate command", dep.migrate_command] if dep.migrate
        output << ["Deployed by",     dep.deployed_by]
        output << ["Started at",      dep.created_at] if dep.created_at
        output << ["Finished at",     dep.finished_at] if dep.finished_at

        output.each do |att, val|
          puts "#\t%-16s %s" % ["#{att}:", val.to_s]
        end
      end

      def deployment_result(dep)
        if dep.successful?
          info 'This deployment was successful.'
        elsif dep.finished_at.nil?
          warn 'This deployment is not finished.'
        else
          say_with_status('This deployment failed.', nil, :red)
        end
      end

      def print_exception(e)
        if e.message.empty? || (e.message == e.class.to_s)
          message = nil
        else
          message = e.message
        end

        if ENV["DEBUG"]
          error(e.class, message)
          e.backtrace.each{|l| say(" "*3 + l) }
        else
          error(message || e.class.to_s)
        end
      end

      def print_help(table)
        print_table(table, :ident => 2, :truncate => true, :colwidth => 20)
      end

      def set_color(string, color, bold=false)
        ($stdout.tty? || ENV['THOR_SHELL']) ? super : string
      end

    end
  end
end
