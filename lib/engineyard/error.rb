module EY
  class Error < RuntimeError; end

  class NoRemotesError < EY::Error
    def initialize(path)
      super "fatal: No git remotes found in #{path}"
    end
  end

  class NoAppError < Error
    def initialize(repo)
      error = [%|There is no application configured for any of the following remotes:|]
      repo.urls.each{|url| error << %|\t#{url}| }
      error << %|You can add this application at #{EY.config.endpoint}|
      super error.join("\n")
    end
  end

  class NoAppMaster < EY::Error
    def initialize(env_name)
      super "The environment '#{env_name}' does not have a master instance."
    end
  end

  class BadAppMasterStatus < EY::Error
    def initialize(master_status)
      super "Application master's status is not \"running\" (green); it is \"#{master_status}\"."
    end
  end

  class EnvironmentError < EY::Error
  end

  class AmbiguousEnvironmentName < EY::EnvironmentError
    def initialize(name, matches)
      pretty_names = matches.map {|x| "'#{x}'"}.join(', ')
      super "The name '#{name}' is ambiguous; it matches all of the following environment names: #{pretty_names}.\n" +
      "Please use a longer, unambiguous substring or the entire environment name."
    end
  end

  class NoSingleEnvironmentError < EY::EnvironmentError
    def initialize(app)
      size = app.environments.size
      super "Unable to determine a single environment for the current application (found #{size} environments)"
    end
  end

  class NoEnvironmentError < EY::EnvironmentError
    def initialize(env_name=nil)
      super "No environment named '#{env_name}'\nYou can create one at #{EY.config.endpoint}"
    end
  end

  class BranchMismatch < EY::Error
    def initialize(default_branch, branch)
      super %|Your deploy branch is set to "#{default_branch}".\n| +
        %|If you want to deploy branch "#{branch}", use --force.|
    end
  end

  class DeployArgumentError < EY::Error
    def initialize
      super %|"deploy" was called incorrectly. Call as "deploy [ENVIRONMENT] [BRANCH]"\n| +
        %|You can set default environments and branches in ey.yml|
    end
  end
end
