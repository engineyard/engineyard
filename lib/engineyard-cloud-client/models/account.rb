require 'engineyard-cloud-client/models/api_struct'

module EY
  class CloudClient
    class Account < ApiStruct.new(:id, :name)
      def add_app(app)
        @apps ||= []
        existing_app = @apps.detect { |a| app.id == a.id }
        unless existing_app
          @apps << app
        end
        existing_app || app
      end

      def apps
        @apps ||= []
      end

      def add_environment(environment)
        @environments ||= []
        existing_environment = @environments.detect { |env| environment.id == env.id }
        unless existing_environment
          @environments << environment
        end
        existing_environment || environment
      end

      def environments
        @environments ||= []
      end
    end
  end
end
