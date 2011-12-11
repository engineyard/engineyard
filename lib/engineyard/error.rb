module EY
  class Error < RuntimeError
  end

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

  class EnvironmentUnlinkedError < EY::Error
    def initialize(env_name)
      super "Environment '#{env_name}' exists but does not run this application."
    end
  end

  class DeployArgumentError < EY::Error
    def initialize
      super(%("deploy" was called incorrectly. Call as "deploy [--environment <env>] [--ref <branch|tag|ref>]"\n) +
        %|You can set default environments and branches in ey.yml|)
    end
  end
end
