require 'engineyard/error'
require 'escape'
require 'pathname'

module EY
  class Repo

    attr_reader :path

    def initialize(repo_path='.')
      self.path = repo_path
    end

    def path=(new_path)
      @path = Pathname.new(new_path).expand_path
    end

    def exist?
      dotgit.directory?
    end

    def current_branch
      if exist? && (head = dotgit("HEAD").read.chomp) && head.gsub!("ref: refs/heads/", "")
        head
      else
        nil
      end
    end

    def urls
      @urls ||= config('remote.*.url').map { |c| c.split.last }
    end

    def has_remote?(repository_uri)
      urls.include?(repository_uri)
    end

    def fail_on_no_remotes!
      if urls.empty?
        raise NoRemotesError.new(path)
      end
    end

    private

    def dotgit(child='')
      path.join('.git', child)
    end

    def config(pattern)
      config_file = Escape.shell_command([dotgit('config').to_s])
      `git config -f #{config_file} --get-regexp '#{pattern}'`.split(/\n/)
    end

  end # Repo
end # EY
