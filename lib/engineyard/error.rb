module EY
  class Error < RuntimeError
  end

  class NoCommandError < EY::Error
    def initialize
      super "Must specify a command to run via ssh"
    end
  end

  class NoInstancesError < EY::Error
    def initialize(env_name)
      super "The environment '#{env_name}' does not have any matching instances."
    end
  end

  class ResolverError        < Error; end
  class NoMatchesError       < ResolverError; end
  class MultipleMatchesError < ResolverError; end

  class AmbiguousEnvironmentGitUriError < ResolverError
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


  class DeployArgumentError < EY::Error; end
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
