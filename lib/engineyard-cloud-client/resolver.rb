require 'engineyard-cloud-client/errors'

module EY
  class CloudClient
    class Resolver
      attr_reader :api, :constraints

      def initialize(api, constraints)
        if constraints.empty?
          raise ArgumentError, "Expected Resolver filtering constraints, got: #{constraints.inspect}"
        end
        @api = api
        @constraints = constraints
      end

      def environment
        if constraints[:app_name]
          raise ArgumentError, "Unexpected option :app_name for Resolver#environment."
        end

        account_and_environment_names = candidates.map { |app_env| [app_env.account_name, app_env.environment_name] }.uniq

        environments = account_and_environment_names.map do |account_name, environment_name|
          api.environments.named(environment_name, account_name)
        end

        case environments.size
        when 0 then raise no_environments_error
        when 1 then environments.first
        else        raise too_many_environments_error(account_and_environment_names, environments)
        end
      end

      def app_environment
        case candidates.size
        when 0 then raise no_app_environments_error
        when 1 then candidates.first
        else        raise too_many_app_environments_error
        end
      end

      private

      def no_environments_error
        if constraints[:environment_name]
          EY::CloudClient::NoEnvironmentError.new(constraints[:environment_name], EY::CloudClient.endpoint)
        else
          EY::CloudClient::NoAppError.new(repo, EY::CloudClient.endpoint)
        end
      end

      def too_many_environments_error(account_and_environment_names, environments)
        if constraints[:environment_name]
          message = "Multiple environments possible, please be more specific:\n\n"
          account_and_environment_names.each do |account_name, environment_name|
            message << "\t#{environment_name.ljust(25)} # ey <command> --environment='#{environment_name}' --account='#{account_name}'\n"
          end
          EY::CloudClient::MultipleMatchesError.new(message)
        else
          EY::CloudClient::AmbiguousEnvironmentGitUriError.new(environments)
        end
      end

      def no_app_environments_error
        if account_candidates.empty? && constraints[:account_name]
          EY::CloudClient::NoMatchesError.new("There were no accounts that matched #{constraints[:account_name]}")
        elsif app_candidates.empty?
          if constraints[:app_name]
            EY::CloudClient::InvalidAppError.new(constraints[:app_name])
          else
            EY::CloudClient::NoAppError.new(repo, EY::CloudClient.endpoint)
          end
        elsif (environment_candidates_matching_account || filter_if_constrained(:environment_name, all)).empty?
          EY::CloudClient::NoEnvironmentError.new(constraints[:environment_name], EY::CloudClient.endpoint)
        else
          message = "The matched apps & environments do not correspond with each other.\n"
          message << "Applications:\n"
          app_candidates.map{|app_env| [app_env.account_name, app_env.app_name]}.uniq.each do |account_name, app_name|
            app = api.apps.named(app_name, account_name)
            message << "\t#{app.name}\n"
            app.environments.each do |env|
              message << "\t\t#{env.name} # ey <command> -e #{env.name} -a #{app.name}\n"
            end
          end
          EY::CloudClient::NoMatchesError.new(message)
        end
      end

      def too_many_app_environments_error
        message = "Multiple app deployments possible, please be more specific:\n\n"
        candidates.map do |app_env|
          [app_env.account_name, app_env.app_name]
        end.uniq.each do |account_name, app_name|
          message << "#{app_name}\n"

          candidates.select do |app_env|
            app_env.app_name == app_name && app_env.account_name == account_name
          end.map do |app_env|
            app_env.environment_name
          end.uniq.each do |env_name|
            message << "\t#{env_name.ljust(25)} # ey <command> --environment='#{env_name}' --app='#{app_name}' --account='#{account_name}'\n"
          end
        end
        EY::CloudClient::MultipleMatchesError.new(message)
      end

      def repo
        constraints[:repo]
      end

      # Ruby 1.8.7 has problems turning AppEnvironment models into hash keys
      # for intersect(&).
      # Ruby 1.9.x does fine, but we have to fall back to a rather primitive
      # way to intersect these arrays by only intersecting the object_ids and
      # then loading them from the array again. :(
      def candidates
        @candidates ||=
          begin
            oid = lambda {|ae| ae.object_id }
            candidate_oids = app_candidates.map(&oid) &
                             environment_candidates.map(&oid) &
                             account_candidates.map(&oid)
            all.select { |app_env| candidate_oids.include?(app_env.object_id) }
          end
      end

      def account_candidates
        @account_candidates ||= filter_if_constrained(:account_name) || all
      end

      def app_candidates
        @app_candidates ||= filter_if_constrained(:app_name, account_candidates) || app_candidates_matching_repo || all
      end

      # first, find only environments
      def environment_candidates
        @environment_candidates ||=
          environment_candidates_matching_app ||
          environment_candidates_matching_account ||
          filter_if_constrained(:environment_name, all) ||
          all
      end

      def all
        @all ||= api.app_environments
      end

      # Returns matches that also match the app if we've be able to narrow by app_candidate.
      def environment_candidates_matching_app
        if !app_candidates.empty? && app_candidates.size < all.size
          filter_if_constrained(:environment_name, app_candidates)
        end
      end

      def environment_candidates_matching_account
        if !account_candidates.empty? && account_candidates.size < all.size
          filter_if_constrained(:environment_name, account_candidates)
        end
      end

      # find by repository uri
      # if none match, return nil
      def app_candidates_matching_repo
        filter(account_candidates) {|app_env| repo && repo.has_remote?(app_env.repository_uri) }
      end

      # If the constraint is set, the only return matches
      # if it is not set, then return all matches
      # returns exact matches, then partial matches, then all
      def filter_if_constrained(key, app_env_set = all)
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
    end
  end
end
