require 'launchy'
require 'engineyard-cloud-client/models'
require 'engineyard-cloud-client/errors'
require 'gitable' # DELETE ME

module EY
  class CloudClient
    class AppEnvironment < ApiStruct.new(:id, :app, :environment, :perform_migration, :migration_command)

      # Return a constrained list of environments given a set of constraints like:
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
        @api = api # delete me
        if matches.empty?
          problems = no_app_environments_error(constraints)
        end
        ResolverResult.new(matches, problems, nil)
      end

      ### DELETE ME FROM HERE

      class << self

        def api
          @api
        end
      def no_app_environments_error(constraints)
        if constraints[:account_name] && account_candidates(constraints).empty?
          # Account specified doesn't exist
          "No account found matching #{constraints[:account_name].inspect}."
        elsif app_candidates(constraints).empty?
          # App not found
          if constraints[:app_name]
            # Specified app not found
            #EY::CloudClient::InvalidAppError.new(constraints[:app_name])
            "No application found matching #{constraints[:app_name].inspect}."
          else
            # Repository not found
            return <<-ERROR
No application configured for any of the following remotes:
\t#{constraints[:remotes].join("\n\t")}
You can add this application at #{EY::CloudClient.endpoint}.
            ERROR
          end
        elsif (environment_candidates_matching_account(constraints) || filter_if_constrained(constraints, :environment_name, all)).empty?
          # Environment doesn't exist
          "No environment found matching #{constraints[:environment_name].inspect}."
        else
          # Account, app, and/or environment found, but don't match
          message = "The matched apps & environments do not correspond with each other.\n"
          message << "Applications:\n"

          ### resolver.apps belongs here.

          app_candidates(constraints).uniq {|app_env| [app_env.account_name, app_env.app_name] }.each do |app_env|
            app = app_env.app
            message << "\t#{app.account.name}/#{app.name}\n"
            app.environments.each do |env|
              message << "\t\t#{env.name} # ey <command> -e #{env.name} -a #{app.name}\n"
            end
          end

          message
        end
      end


      def account_candidates(constraints)
        @account_candidates ||= filter_if_constrained(constraints, :account_name) || all
      end

      def app_candidates(constraints)
        @app_candidates ||= filter_if_constrained(constraints, :app_name, account_candidates(constraints)) || app_candidates_matching_repo(constraints) || all
      end

      # first, find only environments
      def environment_candidates(constraints)
        @environment_candidates ||=
          environment_candidates_matching_app(constraints) ||
          environment_candidates_matching_account(constraints) ||
          filter_if_constrained(constraints,:environment_name, all) ||
          all
      end

      def all
        @all ||= api.app_environments
      end

      # Returns matches that also match the app if we've be able to narrow by app_candidate.
      def environment_candidates_matching_app(constraints)
        if !app_candidates.empty? && app_candidates.size < all.size
          filter_if_constrained(constraints,:environment_name, app_candidates)
        end
      end

      def environment_candidates_matching_account(constraints)
        if !account_candidates(constraints).empty? && account_candidates(constraints).size < all.size
          filter_if_constrained(constraints,:environment_name, account_candidates(constraints))
        end
      end

      # find by repository uri
      # if none match, return nil
      def app_candidates_matching_repo(constraints)
        filter(account_candidates(constraints)) {|app_env| constraints[:remotes] && constraints[:remotes].any? { |uri| Gitable::URI.parse_when_valid(uri).equivalent?(app_env.repository_uri) } }
      end

      # If the constraint is set, the only return matches
      # if it is not set, then return all matches
      # returns exact matches, then partial matches, then all
      def filter_if_constrained(constraints, key, app_env_set = all)
        return unless constraints[key]

        match = constraints[key].downcase

        exact_match   = lambda {|app_env| app_env.send(key) == match }
        partial_match = lambda {|app_env| app_env.send(key).index(match) }

        filter(app_env_set, &exact_match) || filter(app_env_set, &partial_match) || []
      end

      # returns nil if no matches
      # returns an array of matches if any match
      def filter(app_env_set = all, &block)
        matches = app_env_set.select(&block)
        matches.empty? ? nil : matches
      end

      end # class << self

      ### DELETE ME TO HERE

      def initialize(api, attrs)
        super

        raise ArgumentError, 'AppEnvironment created without app!' unless app
        raise ArgumentError, 'AppEnvironment created without environment!' unless environment

        if environment.deployment_configurations
          extract_deploy_config(environment.deployment_configurations[app.name])
        end
      end

      def app=(app_or_hash)
        super App.from_hash(api, app_or_hash)
      end

      def environment=(env_or_hash)
        super Environment.from_hash(api, env_or_hash)
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

      # hack for legacy api.
      def extract_deploy_config(deploy_config)
        if deploy_config
          self.migration_command = deploy_config['migrate']['command']
          self.perform_migration = deploy_config['migrate']['perform']
        end
      end

      def last_deployment
        Deployment.last(api, self)
      end

      def new_deployment(attrs)
        Deployment.from_hash(api, attrs.merge(:app_environment => self))
      end

      def rollback(extra_config, verbose)
        environment.bridge!.rollback(app, extra_config, verbose)
      end

      def take_down_maintenance_page(verbose=false)
        environment.bridge!.take_down_maintenance_page(app, verbose)
      end

      def put_up_maintenance_page(verbose=false)
        environment.bridge!.put_up_maintenance_page(app, verbose)
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
