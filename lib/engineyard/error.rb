module EY
  class Error < RuntimeError
    def ambiguous(type, name, matches, desc="")
      pretty_names = matches.map {|x| "'#{x}'"}.join(', ')
      "The name '#{name}' is ambiguous; it matches all of the following #{type} names: #{pretty_names}.\n" +
      "Please use a longer, unambiguous substring or the entire #{type} name." + desc
    end
  end

  class ResolveError < EY::Error; end
  class NoMatchesError < ResolveError; end
  class MultipleMatchesError < ResolveError; end

  class NoCommandError < EY::Error
    def initialize
      super "Must specify a command to run via ssh"
    end
  end

  class NoRemotesError < EY::Error
    def initialize(path)
      super "fatal: No git remotes found in #{path}"
    end
  end

  class NoAppError < Error
    def initialize(repo)
      super <<-ERROR
There is no application configured for any of the following remotes:
\t#{repo ? repo.urls.join("\n\t") : "No remotes found."}
You can add this application at #{EY.config.endpoint}
      ERROR
    end
  end

  class InvalidAppError < Error
    def initialize(name)
      super %|There is no app configured with the name "#{name}"|
    end
  end

  class AmbiguousAppNameError < EY::Error
    def initialize(name, matches, desc="")
      super ambiguous("app", name, matches, desc)
    end
  end

  class NoAppMasterError < EY::Error
    def initialize(env_name)
      super "The environment '#{env_name}' does not have a master instance."
    end
  end

  class NoInstancesError < EY::Error
    def initialize(env_name)
      super "The environment '#{env_name}' does not have any matching instances."
    end
  end

  class BadAppMasterStatusError < EY::Error
    def initialize(master_status)
      super "Application master's status is not \"running\" (green); it is \"#{master_status}\"."
    end
  end

  class EnvironmentError < EY::Error
  end

  class AmbiguousEnvironmentNameError < EY::EnvironmentError
    def initialize(name, matches, desc="")
      super ambiguous("environment", name, matches, desc)
    end
  end

  class AmbiguousEnvironmentGitUriError < EY::EnvironmentError
    def initialize(environments)
      message = "The repository url in this directory is ambiguous.\n"
      message << "Please use -e <envname> to specify one of the following environments:\n"
      environments.sort do |a, b|
        if a.account == b.account
          a.name <=> b.name
        else
          a.account.name <=> b.account.name
        end
      end.each { |env| message << "\t#{env.name} (#{env.account.name})\n" }
      super message
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

  class EnvironmentUnlinkedError < EY::Error
    def initialize(env_name)
      super "Environment '#{env_name}' exists but does not run this application."
    end
  end

  class BranchMismatchError < EY::Error
    def initialize(default_branch, branch)
      super(%|Your deploy branch is set to "#{default_branch}".\n| +
        %|If you want to deploy branch "#{branch}", use --ignore-default-branch.|)
    end
  end

  class DeployArgumentError < EY::Error
    def initialize
      super(%("deploy" was called incorrectly. Call as "deploy [--environment <env>] [--ref <branch|tag|ref>]"\n) +
        %|You can set default environments and branches in ey.yml|)
    end
  end
end
