require 'escape'

module EY
  class APIClient
    class Deployment < ApiStruct.new(:id, :app, :created_at, :commit, :environment, :finished_at, :migrate_command, :output, :ref, :resolved_ref, :successful, :user_name)
      def self.api_root(app_id, environment_id)
        "/apps/#{app_id}/environments/#{environment_id}/deployments"
      end

      def self.last(app, environment, api)
        get(app, environment, 'last', api)
      end

      def self.get(app, environment, id, api)
        response = api.request(api_root(app.id, environment.id) + "/#{id}", :method => :get)
        load_from_response app, environment, response
      rescue EY::APIClient::ResourceNotFound
        nil
      end

      def self.load_from_response(app, environment, response)
        dep = new
        dep.app = app
        dep.environment = environment
        dep.update_with_response(response)
        dep
      end

      def self.started(environment, app, ref, migrate_command)
        deployment = from_hash({
          :app             => app,
          :environment     => environment,
          :migrate_command => migrate_command,
          :ref             => ref,
        })
        deployment.start
        deployment
      end

      def migrate
        !!migrate_command
      end

      alias successful? successful

      def start
        post_to_api({
          :migrate         => migrate,
          :migrate_command => migrate_command,
          :output          => output,
          :ref             => ref,
        })
      end

      def finished(successful, output)
        self.successful = successful
        self.output = output
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

      def api
        app.api
      end
    end
  end
end
