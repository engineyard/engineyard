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

    def uri
      config = `git config -f #{@path}/.git/config remote.origin.url`.strip
      config.empty? ? nil : config
    end
    alias_method :url, :uri
  end # Repo
end # EY