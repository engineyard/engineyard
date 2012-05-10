module EY
  class Repo

    def initialize(path=File.expand_path('.'))
      @path = path
    end

    def current_branch
      if File.directory?(File.join(@path, ".git"))
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
      lines = `git config -f #{@path}/.git/config --get-regexp 'remote.*.url'`.split(/\n/)
      raise NoRemotesError.new(@path) if lines.empty?
      lines.map { |c| c.split.last }
    end

  end # Repo
end # EY
