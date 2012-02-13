module EY
  class CloudClient
    class Error < RuntimeError
    end

    class RequestFailed      < Error; end
    class InvalidCredentials < RequestFailed; end
    class ResourceNotFound   < RequestFailed; end

    class BadEndpointError < Error
      def initialize(endpoint)
        super "#{endpoint.inspect} is not a valid endpoint URI. Endpoint must be an absolute URI."
      end
    end

    class AttributeRequiredError < Error
      def initialize(attribute_name, klass = nil)
        if klass
          super "Attribute '#{attribute_name}' of class #{klass} is required for this action."
        else
          super "Attribute '#{attribute_name}' is required for this action."
        end
      end
    end

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

    class EnvironmentUnlinkedError < Error
      def initialize(env_name)
        super "Environment '#{env_name}' exists but does not run this application."
      end
    end
  end
end
