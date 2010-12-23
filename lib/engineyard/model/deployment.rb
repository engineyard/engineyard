require 'escape'

module EY
  module Model
    class Deployment < ApiStruct.new(:id, :app, :created_at, :environment, :finished_at, :migration_command, :output, :ref, :successful)
      def self.started(environment, app, ref, migration_command)
        from_hash({
          :app               => app,
          :environment       => environment,
          :migration_command => migration_command,
          :ref               => ref,
          :created_at        => Time.now,
        })
      end

      def finished(successful, output)
        self.successful = successful
        self.output = output
        self.finished_at = Time.now
        post_to_appcloud!
      end

      private

      def post_to_appcloud!
        api.request(api_uri, :method => :post, :params => params)
        EY.ui.info "Deployment recorded in AppCloud"
      end

      def params
        {:deployment => {
          :created_at      => created_at,
          :finished_at     => finished_at,
          :migrate         => !!migration_command,
          :migrate_command => migration_command,
          :output          => output,
          :ref             => ref,
          :successful      => successful,
          }}
      end

      def api_uri
        "/apps/#{app.id}/environments/#{environment.id}/deployments"
      end

      def api
        app.api
      end
    end
  end
end
