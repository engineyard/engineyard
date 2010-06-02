module EY
  class Error < RuntimeError; end

  class NoRemotesError < EY::Error
    def initialize(path)
      super "fatal: No git remotes found in #{path}"
    end
  end

  class NoAppError < Error
    def initialize(repo)
      @repo = repo
    end

    def message
      error = [%|There is no application configured for any of the following remotes:|]
      @repo.urls.each{|url| error << %|\t#{url}| }
      error << %|You can add this application at #{EY.config.endpoint}|
        error.join("\n")
    end
  end

  class NoAppMaster < EY::Error
    def initialize(env_name)
      @env_name = env_name
    end

    def message
      "The environment '#{@env_name}' does not have a master instance."
    end
  end

  class EnvironmentError < EY::Error
  end

  class AmbiguousEnvironmentName < EY::Error
    def initialize(name, matches)
      @name, @matches = name, matches
    end

    def message
      pretty_names = @matches.map {|x| "'#{x}'"}.join(', ')
      "The name '#{@name}' is ambiguous; it matches all of the following environment names: #{pretty_names}.\nPlease use a longer, unambiguous substring or the entire environment name."
    end
  end

  class NoSingleEnvironmentError < EY::Error
    def initialize(app)
      @envs = app.environments
    end

    def message
      "Unable to determine a single environment for the current application (found #{@envs.size} environments)"
    end
  end

  class NoEnvironmentError < EY::Error
    def initialize(env_name=nil)
      @env_name = env_name
    end

    def message
      "No environment named '#{@env_name}'\nYou can create one at #{EY.config.endpoint}"
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
