module EY
  class APIClient
    class Error < RuntimeError
    end

    class BadEndpointError < Error
      def initialize(endpoint)
        super "#{endpoint.inspect} is not a valid endpoint URI. Endpoint must be an absolute URI."
      end
    end

    class AmbiguousError < Error
      def initialize(type, name, matches, desc="")
        pretty_names = matches.map {|x| "'#{x}'"}.join(', ')
        super "The name '#{name}' is ambiguous; it matches all of the following #{type} names: #{pretty_names}.\n" +
        "Please use a longer, unambiguous substring or the entire #{type} name." + desc
      end
    end

    class ResolverError < Error; end
    class NoMatchesError < ResolverError; end
    class MultipleMatchesError < ResolverError; end

    class NoAppError < Error
      def initialize(repo, endpoint)
        super <<-ERROR
There is no application configured for any of the following remotes:
\t#{repo ? repo.urls.join("\n\t") : "No remotes found."}
You can add this application at #{endpoint}
        ERROR
      end
    end

    class InvalidAppError < Error
      def initialize(name)
        super %|There is no app configured with the name "#{name}"|
      end
    end

    class AmbiguousAppNameError < AmbiguousError
      def initialize(name, matches, desc="")
        super("app", name, matches, desc)
      end
    end

    class NoAppMasterError < Error
      def initialize(env_name)
        super "The environment '#{env_name}' does not have a master instance."
      end
    end

    class NoInstancesError < Error
      def initialize(env_name)
        super "The environment '#{env_name}' does not have any matching instances."
      end
    end

    class BadAppMasterStatusError < Error
      def initialize(master_status)
        super "Application master's status is not \"running\" (green); it is \"#{master_status}\"."
      end
    end

    class EnvironmentError < Error
    end

    class AmbiguousEnvironmentNameError < AmbiguousError
      def initialize(name, matches, desc="")
        super("environment", name, matches, desc)
      end
    end

    class AmbiguousEnvironmentGitUriError < EnvironmentError
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

    class NoSingleEnvironmentError < EnvironmentError
      def initialize(app)
        size = app.environments.size
        super "Unable to determine a single environment for the current application (found #{size} environments)"
      end
    end

    class NoEnvironmentError < EnvironmentError
      def initialize(env_name, endpoint = EY::APIClient.endpoint)
        super "No environment named '#{env_name}'\nYou can create one at #{endpoint}"
      end
    end

    class EnvironmentUnlinkedError < Error
      def initialize(env_name)
        super "Environment '#{env_name}' exists but does not run this application."
      end
    end

    class BranchMismatchError < Error
      def initialize(default_branch, branch)
        super(%|Your deploy branch is set to "#{default_branch}".\n| +
          %|If you want to deploy branch "#{branch}", use --ignore-default-branch.|)
      end
    end
  end
end
