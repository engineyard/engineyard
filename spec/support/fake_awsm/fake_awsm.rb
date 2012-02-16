module EY
  class << self
    def fake_awsm
      @fake_awsm ||= load_fake_awsm
    end
    alias_method :start_fake_awsm, :fake_awsm

    def define_git_repo(name, &setup)
      git_repo_setup[name] ||= setup
    end

    def refresh_git_repo(name)
      git_repo_dir_cache.delete name
    end

    def git_repo_dir(name)
      return git_repo_dir_cache[name] if git_repo_dir_cache.has_key?(name)
      raise ArgumentError, "No definition for git repo #{name}" unless git_repo_setup[name]

      git_dir = Pathname.new("/tmp/engineyard_test_repo_#{Time.now.tv_sec}_#{Time.now.tv_usec}_#{$$}")
      git_dir.mkdir
      Dir.chdir(git_dir) do
        system("git init -q")
        system('git config user.email ey@spec.test')
        system('git config user.name "EY Specs"')
        system("git remote add testremote user@git.host:path/to/repo.git")
        git_repo_setup[name].call(git_dir)
      end
      git_repo_dir_cache[name] = git_dir
    end

    protected

    def load_fake_awsm
      config_ru = File.join(EY_ROOT, "spec/support/fake_awsm/config.ru")
      unless system("ruby -c '#{config_ru}' > /dev/null")
        raise SyntaxError, "There is a syntax error in fake_awsm/config.ru! fix it!"
      end
      @server = RealWeb.start_server_in_fork(config_ru)
      "http://localhost:#{@server.port}"
    end

    def git_repo_setup
      @git_repo_setup ||= {}
    end

    def git_repo_dir_cache
      @git_repo_dir_cache ||= {}
    end
  end
end
