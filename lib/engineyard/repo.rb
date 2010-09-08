require 'escape'

module EY
  class Repo

    def initialize(path=File.expand_path('.'))
      @path = path
    end

    def exists?
      File.directory?(File.join(@path, ".git"))
    end

    def current_branch
      if exists?
        head = File.read(File.join(@path, ".git/HEAD")).chomp
        if head.gsub!("ref: refs/heads/", "")
          head
        else
          nil
        end
      else
        nil
      end
    end

    def urls
      lines = `git config -f #{Escape.shell_command(@path)}/.git/config --get-regexp 'remote.*.url'`.split(/\n/)
      raise NoRemotesError.new(@path) if lines.empty?
      lines.map { |c| c.split.last }
    end

  end # Repo
end # EY
