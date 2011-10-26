require 'engineyard/error'
require 'escape'
require 'pathname'
require 'yaml'

module EY
  class Repo
    class NotAGitRepository < EY::Error
      attr_reader :dir
      def initialize(output, dir)
        @dir = dir
        super("#{output} (#{dir})")
      end
    end

    def self.env_git_repo?
      Dir.chdir(File.expand_path(env_git_dir)) do
        system('git rev-parse >/dev/null 2>&1')
      end
    end

    def self.env_git_dir
      File.expand_path(ENV['GIT_DIR'] || ENV['GIT_WORK_TREE'] || '.')
    end

    attr_reader :root

    # $GIT_DIR is what git uses to override the location of the .git dir.
    # $GIT_WORK_TREE is the working tree for git, which we'll use after $GIT_DIR.
    #
    # We use this to specify which repo we should look at, since it would also
    # specify where any git commands are directed, thus fooling commands we
    # run anyway.
    def initialize
      dir = self.class.env_git_dir
      Dir.chdir(dir) do
        out = `git rev-parse --git-dir 2>&1`.chomp

        if $?.success?
          # process dir is changed so expand_path is relative to chdir.
          @git_dir = File.expand_path(out)
        else
          raise EY::Repo::NotAGitRepository.new(out, dir)
        end
      end

      root = run("git rev-parse --show-toplevel 2>&1").strip
      if $?.success? && !root.empty?
        @root = Pathname.new(root)
      end
    end

    def run(command)
      if $DEBUG
        EY.ui.debug("% #{command}")
      end
      `#{command}`
    end

    def has_committed_file?(file)
      run("git ls-files --full-name #{file}").strip == file && $?.success?
    end

    def has_file?(file)
      has_committed_file?(file) || root.join(file).exist?
    end

    # Read the committed version at HEAD (or ref) of a file using the git working tree relative filename.
    # If the file is not committed, but does exist, a warning will be displayed
    # and the file will be read anyway.
    # If the file does not exist, returns nil.
    #
    # Example:
    #
    #   read_file('config/ey.yml') # will read $GIT_WORK_TREE/config/ey.yml
    #
    def read_file(file, ref = 'HEAD')
      if has_committed_file?(file)
        # TODO warn if there are unstaged changes.
        run("git show #{ref}:#{file}")
      else
        EY.ui.warn <<-WARN
Warn: #{file} is not committed to this git repository: #{root}
This can prevent ey deploy from loading this file for certain server side
deploy-time operations. Commit this file to fix this warning.
        WARN
        root.join(file).read
      end
    end

    def current_branch
      branch = run("git symbolic-ref -q HEAD").chomp.gsub("refs/heads/", "")
      branch.empty? ? nil : branch
    end

    def urls
      @urls ||= run("git remote -v").scan(/\t[^\s]+\s/).map { |c| c.strip }
    end

    def has_remote?(repository_uri)
      urls.include?(repository_uri)
    end

    def fail_on_no_remotes!
      if urls.empty?
        raise NoRemotesError.new(root)
      end
    end

  end # Repo
end # EY
