module EY
  class Repo

    def initialize(path=File.expand_path('.'))
      @path = path
    end

    def current_branch
      head = File.read(File.join(@path, ".git/HEAD")).chomp
      if head.gsub!("ref: refs/heads/", "")
        head
      else
        nil
      end
    end

    def urls
      `git config -f #{@path}/.git/config --get-regexp 'remote.*.url'`.split(/\n/).map do |c|
        c.split.last
      end
    end

  end # Repo
end # EY