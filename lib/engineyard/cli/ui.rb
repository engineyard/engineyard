module EY
  class CLI
    class UI < Thor::Base.shell

      class Prompter
        class Mock
          def next_answer=(arg)
            @answers ||= []
            @answers << arg
          end
          def ask(*args, &block)
            @questions ||= []
            @questions << args.first
            @answers.pop
          end
          attr_reader :questions
        end
        def self.enable_mock!
          @backend = Mock.new
        end
        def self.backend
          require 'highline'
          @backend ||= HighLine.new($stdin)
        end
        def self.ask(*args, &block)
          backend.ask(*args, &block)
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

      def ask(message, password = false)
        begin
          if !$stdin || !$stdin.tty?
            Prompter.ask(message)
          elsif password
            Prompter.ask(message) {|q| q.echo = "*" }
          else
            Prompter.ask(message) {|q| q.readline = true }
          end
        rescue EOFError
          return ''
        end
      end

      def print_envs(apps, default_env_name = nil, simple = false)
        if simple
          envs = apps.map{ |a| a.environments }
          puts envs.flatten.map{|x| x.name}.uniq
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
        puts "# Status of last deployment of #{dep.app.account.name}/#{dep.app.name}/#{dep.environment.name}:"
        puts "#"

        output = []
        output << ["Account",         dep.app.account.name]
        output << ["Application",     dep.app.name]
        output << ["Environment",     dep.environment.name]
        output << ["Input Ref",       dep.ref]
        output << ["Resolved Ref",    dep.ref]
        output << ["Commit",          dep.commit || '(Unable to resolve)']
        output << ["Migrate",         dep.migrate]
        output << ["Migrate command", dep.migrate_command] if dep.migrate
        output << ["Deployed by",     dep.user_name]
        output << ["Created at",      dep.created_at]
        output << ["Finished at",     dep.finished_at]

        output.each do |att, val|
          puts "#\t%-15s %s" % ["#{att}:", val.to_s]
        end
        puts "#"

        if dep.successful?
          info 'Deployment was successful.'
        elsif dep.finished_at.nil?
          warn 'Deployment is not finished.'
        else
          say_with_status('Deployment failed.', nil, :red)
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
