module EY
  class CLI
    class UI < Thor::Base.shell

      def error(name, message = nil)
        begin
          orig_out, $stdout = $stdout, $stderr
          if message
            say_status name, message, :red
          elsif name
            say name, :red
          end
        ensure
          $stdout = orig_out
        end
      end

      def warn(name, message = nil)
        if message
          say_status name, message, :yellow
        elsif name
          say name, :yellow
        end
      end

      def info(name, message = nil)
        if message
          say_status name, message, :green
        elsif name
          say name, :green
        end
      end

      def debug(name, message = nil)
        return unless ENV["DEBUG"]

        if message
          message = message.inspect unless message.is_a?(String)
          say_status name, message, :blue
        elsif name
          name = name.inspect unless name.is_a?(String)
          say name, :cyan
        end
      end

      def ask(message, password = false)
        unless password
          super(message)
        else
          EY.library 'highline'
          @hl ||= HighLine.new($stdin)
          @hl.ask(message) {|q| q.echo = "*" }
        end
      end

      def print_envs(envs, default_env = nil)
        printable_envs = envs.map do |e|
          icount = e.instances_count
          iname = (icount == 1) ? "instance" : "instances"

          e.name << " (default)" if e.name == default_env
          env = [e.name]
          env << "#{icount} #{iname}"
          env << e.apps.map{|a| a.name }.join(", ")
        end
        print_table(printable_envs, :ident => 2)
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

    end
  end
end