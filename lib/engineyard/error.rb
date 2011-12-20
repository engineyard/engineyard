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
  end

  class BranchMismatchError < DeployArgumentError
    def initialize(default, ref)
      super <<-ERR
Your default branch is set to #{default.inspect} in ey.yml.
To deploy #{ref.inspect} you can:
  * Delete the line 'branch: #{default}' in ey.yml
OR
  * Use the -R [REF] or --force-ref [REF] options as follows:
Usage: ey deploy -R #{ref}
       ey deploy --force-ref #{ref}
      ERR
    end
  end

  class RefAndMigrateRequiredOutsideRepo < DeployArgumentError
    def initialize(options)
      super <<-ERR
Because defaults are stored in a file in your application dir, when specifying
--app you must also specify the --ref and the --migrate or --no-migrate options.
Usage: ey deploy --app #{options[:app]} --ref [ref] --migrate [COMMAND]
       ey deploy --app #{options[:app]} --ref [branch] --no-migrate
      ERR
    end
  end

  class RefRequired < DeployArgumentError
    def initialize(options)
      super <<-ERR
Unable to determine the branch or ref to deploy
Usage: ey deploy --ref [ref]
      ERR
    end
  end

  class MigrateRequired < DeployArgumentError
    def initialize(options)
      super <<-ERR
Unable to determine migration choice. ey deploy no longer migrates by default.
Usage: ey deploy --migrate
       ey deploy --no-migrate
      ERR
    end
  end
end
