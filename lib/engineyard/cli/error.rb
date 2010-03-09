module EY
  class CLI < Thor
    class EnvironmentError < EY::Error; end

    class NoAppError < EY::Error
      def initialize(repo)
        @repo = repo
      end

      def message
        error = [%|There is no application configured for any of the following remotes:|]
        @repo.urls.each{|url| error << %|\t#{url}| }
        error << %|You can add this application at cloud.engineyard.com|
        error.join("\n")
      end
    end

    class BranchMismatch < EY::Error
      def initialize(default_branch, branch)
        super(nil)
        @default_branch, @branch = default_branch, branch
      end

      def message
        %|Your deploy branch is set to "#{@default_branch}".\n| +
          %|If you want to deploy branch "#{@branch}", use --force.|
      end
    end

    class DeployArgumentError < EY::Error
      def message
        %|"deploy" was called incorrectly. Call as "deploy [ENVIRONMENT] [BRANCH]"\n| +
          %|You can set default environments and branches in ey.yml|
      end
    end
  end
end