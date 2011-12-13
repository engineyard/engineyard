require 'escape'

module EY
  class APIClient
    class Deployment < ApiStruct.new(:id, :app_environment, :created_at, :commit, :finished_at, :migrate_command, :output, :ref, :resolved_ref, :successful, :user_name)
      def self.api_root(app_id, environment_id)
        "/apps/#{app_id}/environments/#{environment_id}/deployments"
      end

      def self.last(api, app_environment)
        get(api, app_environment, 'last')
      end

      def self.get(api, app_environment, id)
        uri = api_root(app_environment.app.id, app_environment.environment.id) + "/#{id}"
        response = api.request(uri, :method => :get)
        load_from_response api, app_environment, response
      rescue EY::APIClient::ResourceNotFound
        nil
      end

      def self.load_from_response(api, app_environment, response)
        dep = from_hash(api, {:app_environment => app_environment})
        dep.update_with_response(response)
        dep
      end

      def self.started(api, app_environment, ref, migrate_command)
        deployment = from_hash(api, {
          :app_environment => app_environment,
          :migrate_command => migrate_command,
          :ref             => ref,
        })
        deployment.start
        deployment
      end

      def app
        app_environment.app
      end

      def environment
        app_environment.environment
      end

      def migrate
        !!migrate_command
      end

      alias_method :migration_command, :migrate_command
      alias_method :migration_command=, :migrate_command=

      alias successful? successful

      def start
        post_to_api({
          :migrate         => migrate,
          :migrate_command => migrate_command,
          :output          => output,
          :ref             => ref,
        })
      end

      def append_output(out)
        @output ||= ''
        @output << out
      end

      def finished
        put_to_api({:successful => successful, :output => output})
      end

      def update_with_response(response)
        response['deployment'].each do |key,val|
          send("#{key}=", val) if respond_to?("#{key}=")
        end
      end

      private

      def post_to_api(params)
        update_with_response api.request(collection_uri, :method => :post, :params => {:deployment => params})
      end

      def put_to_api(params)
        update_with_response api.request(member_uri("/finished"), :method => :put, :params => {:deployment => params})
      end

      def collection_uri
        self.class.api_root(app.id, environment.id)
      end

      def member_uri(path = nil)
        collection_uri + "/#{id}#{path}"
      end
    end
  end
end
