require 'engineyard/error'
require 'pathname'

module EY
  class Repo
    class NotAGitRepository < EY::Error
      attr_reader :dir
      def initialize(output)
        @dir = File.expand_path(ENV['GIT_DIR'] || ENV['GIT_WORK_TREE'] || '.')
        super("#{output} (#{@dir})")
      end
    end

    class NoRemotesError < EY::Error
      def initialize(path)
        super "fatal: No git remotes found in #{path}"
      end
    end

    def self.exist?
      `git rev-parse --git-dir 2>&1`
      $?.success?
    end

    attr_reader :root

    # $GIT_DIR is what git uses to override the location of the .git dir.
    # $GIT_WORK_TREE is the working tree for git, which we'll use after $GIT_DIR.
    #
    # We use this to specify which repo we should look at, since it would also
    # specify where any git commands are directed, thus fooling commands we
    # run anyway.
    def initialize
    end

    def root
      @root ||= begin
                  out = `git rev-parse --show-toplevel 2>&1`.strip

                  if $?.success? && !out.empty?
                    Pathname.new(out)
                  else
                    raise EY::Repo::NotAGitRepository.new(out)
                  end
                end
    end

    def ensure_repository!
      root
    end

    def has_committed_file?(file)
      ensure_repository!
      `git ls-files --full-name #{file}`.strip == file && $?.success?
    end

    def has_file?(file)
      ensure_repository!
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
      ensure_repository!
      if has_committed_file?(file)
        # TODO warn if there are unstaged changes.
        `git show #{ref}:#{file}`
      else
        EY.ui.warn <<-WARN
Warn: #{file} is not committed to this git repository:
\t#{root}
This can prevent ey deploy from loading this file for certain server side
deploy-time operations. Commit this file to fix this warning.
        WARN
        root.join(file).read
      end
    end

    def current_branch
      ensure_repository!
      branch = `git symbolic-ref -q HEAD`.chomp.gsub("refs/heads/", "")
      branch.empty? ? nil : branch
    end

    def remotes
      ensure_repository!
      @remotes ||= `git remote -v`.scan(/\t[^\s]+\s/).map { |c| c.strip }.uniq
    end

    def fail_on_no_remotes!
      if remotes.empty?
        raise EY::Repo::NoRemotesError.new(root)
      end
    end

  end # Repo
end # EY
