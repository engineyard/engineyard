module EY
  class UI < Thor::Base.shell

    def error(name, message = nil)
      raise RuntimeError, "NO YUO"
    end

    def warn(name, message = nil)
      raise RuntimeError, "NO YUO"
    end

    def info(name, message = nil)
      raise RuntimeError, "NO YUO"
    end

    def debug(name, message = nil)
      return unless ENV["DEBUG"]

      if message
        say_status name, message, :blue
      elsif name
        say name, :cyan
      end
    end

    def print_exception(e)
      raise RuntimeError, "NO YUO"
    end

  end # UI
end # EY