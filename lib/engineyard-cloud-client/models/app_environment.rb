require 'launchy'
require 'engineyard-cloud-client/models'
require 'engineyard-cloud-client/errors'
require 'gitable' # DELETE ME

module EY
  class CloudClient
    class AppEnvironment < ApiStruct.new(:id, :app, :environment, :uri, :domain_name, :migrate_command, :migrate)

      # Return a constrained list of app_environments given a set of constraints like:
      #
      # * app_name
      # * account_name
      # * environment_name
      # * remotes:  An array of git remote URIs
      #
      def self.resolve(api, constraints)
        clean_constraints = constraints.reject { |k,v| v.nil? }
        params = {'constraints' => clean_constraints}
        response = api.request("/app_environments/resolve", :method => :get, :params => params)
        matches = from_array(api, response['app_environments'])
        ResolverResult.new(api, matches, response['errors'], response['suggestions'])
      end

      def initialize(api, attrs)
        super

        raise ArgumentError, 'AppEnvironment created without app!'         unless app
        raise ArgumentError, 'AppEnvironment created without environment!' unless environment
      end

      def app=(app_or_hash)
        super App.from_hash(api, app_or_hash)
        app.add_app_environment(self)
        app
      end

      def environment=(env_or_hash)
        super Environment.from_hash(api, env_or_hash)
        environment.add_app_environment(self)
        environment
      end

      def account_name
        app.account_name
      end

      def app_name
        app.name
      end

      def environment_name
        environment.name
      end

      def repository_uri
        app.repository_uri
      end

      def to_hierarchy_str
        [account_name, app_name, environment_name].join('/')
      end

      def last_deployment
        Deployment.last(api, self)
      end

      def new_deployment(attrs)
        Deployment.from_hash(api, attrs.merge(:app_environment => self))
      end

      def short_environment_name
        environment.name.gsub(/^#{Regexp.quote(app.name)}_/, '')
      end

      def launch
        Launchy.open(environment.bridge!.hostname_url)
      end

    end
  end
end
