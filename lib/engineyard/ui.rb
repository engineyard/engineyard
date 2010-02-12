module EY
  class UI < Thor::Base.shell
    def error(name, message = nil)
      if message
        say_status name, message, :red
      else
        say name, :red
      end
    end

    def warn(name, message = nil)
      if message
        say_status name, message, :yellow
      else
        say name, :yellow
      end
    end

    def info(name, message = nil)
      if message
        say_status name, message, :green
      else
        say name, :green
      end
    end

    def debug(name, message = nil)
      return unless ENV["DEBUG"]

      if message
        say_status name, message, :blue
      else
        say name, :cyan
      end
    end

    def ask(message, password = false, input = $stdin)
      unless password
        super(message)
      else
        EY.library 'highline'
        hl = HighLine.new(input)
        hl.ask(message) {|q| q.echo = "*" }
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
        e.backtrace.each{|l| EY.ui.say(" "*3 + l) }
      else
        error(message)
      end
    end

  end # UI
end # EY