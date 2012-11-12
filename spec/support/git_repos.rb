module EY
  class << self
    def define_git_repo(name, &setup)
      git_repo_setup[name] ||= setup
    end

    def refresh_git_repo(name)
      git_repo_dir_cache.delete name
    end

    def git_repo_dir(name)
      return git_repo_dir_cache[name] if git_repo_dir_cache.has_key?(name)
      raise ArgumentError, "No definition for git repo #{name}" unless git_repo_setup[name]

      git_dir = TMPDIR.join("engineyard_test_repo_#{Time.now.tv_sec}_#{Time.now.tv_usec}_#{$$}")
      git_dir.mkpath
      Dir.chdir(git_dir) do
        system("git init -q")
        system('git config user.email ey@spec.test')
        system('git config user.name "EY Specs"')
        system("git remote add testremote user@git.host:path/to/repo.git")
        git_repo_setup[name].call(git_dir)
      end
      git_repo_dir_cache[name] = git_dir
    end

    def chdir_to_repo(repo_name)
      @_original_wd ||= []
      @_original_wd << Dir.getwd
      Dir.chdir(git_repo_dir(repo_name))
    end

    def chdir_return
      Dir.chdir(@_original_wd.pop) if @_original_wd && @_original_wd.any?
    end

    def fixture_recipes_tgz
      File.expand_path('../fixture_recipes.tgz', __FILE__)
    end

    def link_recipes_tgz(git_dir)
      system("ln -s #{fixture_recipes_tgz} #{git_dir.join('recipes.tgz')}")
    end

    protected

    def git_repo_setup
      @git_repo_setup ||= {}
    end

    def git_repo_dir_cache
      @git_repo_dir_cache ||= {}
    end
  end

  define_git_repo("default") do |git_dir|
    system("echo 'source :gemcutter' > Gemfile")
    system("git add Gemfile")
    system("git commit -m 'initial commit' >/dev/null 2>&1")
  end

  define_git_repo('deploy test') do
    # we'll have one commit on master
    system("echo 'source :gemcutter' > Gemfile")
    system("git add Gemfile")
    system("git commit -m 'initial commit' >/dev/null 2>&1")

    # and a tag
    system("git tag -a -m 'version one' v1")

    # and we need a non-master branch
    system("git checkout -b current-branch >/dev/null 2>&1")
  end

  define_git_repo('+cookbooks') do |git_dir|
    git_dir.join("cookbooks").mkdir
    git_dir.join("cookbooks/file").open("w") {|f| f << "boo" }
  end

  define_git_repo('+recipes') do |git_dir|
    link_recipes_tgz(git_dir)
  end

  define_git_repo "only cookbooks, no remotes" do |git_dir|
    `git --git-dir "#{git_dir}/.git" remote`.split("\n").each do |remote|
      `git --git-dir "#{git_dir}/.git" remote rm #{remote}`
    end

    git_dir.join("cookbooks").mkdir
    File.open(git_dir.join("cookbooks/file"), "w"){|f| f << "stuff" }
  end

  define_git_repo "only cookbooks, unrelated remotes" do |git_dir|
    `git --git-dir "#{git_dir}/.git" remote`.split("\n").each do |remote|
      `git --git-dir "#{git_dir}/.git" remote rm #{remote}`
    end

    `git remote add origin polly@pirate.example.com:wanna/cracker.git`

    git_dir.join("cookbooks").mkdir
    File.open(git_dir.join("cookbooks/file"), "w"){|f| f << "rawk" }
  end

  define_git_repo('dup test') do
    system("git remote add dup git://github.com/engineyard/dup.git")
  end

  define_git_repo("not actually a git repo") do |git_dir|
    # in case we screw up and are not in a freshly-generated test
    # git repository, don't blow away the thing we're developing
    system("rm -rf .git") if `git remote -v`.include?("path/to/repo.git")
    git_dir.join("cookbooks").mkdir
    link_recipes_tgz(git_dir)
  end
end
