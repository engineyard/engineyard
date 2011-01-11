require 'escape'

module EY
  module Model
    class Deployment < ApiStruct.new(:id, :app, :created_at, :commit, :environment, :finished_at, :migrate_command, :output, :ref, :resolved_ref, :successful)
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

      def start
        post_to_api({
          :migrate         => !!migrate_command,
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

      private

      def post_to_api(params)
        update_with_response api.request(collection_uri, :method => :post, :params => {:deployment => params})
      end

      def put_to_api(params)
        update_with_response api.request(member_uri("/finished"), :method => :put, :params => {:deployment => params})
      end

      def update_with_response(response)
        data = response['deployment']
        data.each do |key,val|
          self.send("#{key}=", val) if respond_to?("#{key}=")
        end
      end

      def collection_uri
        "/apps/#{app.id}/environments/#{environment.id}/deployments"
      end

      def member_uri(path = nil)
        "/apps/#{app.id}/environments/#{environment.id}/deployments/#{id}#{path}"
      end

      def api
        app.api
      end
    end
  end
end
