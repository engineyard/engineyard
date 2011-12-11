module EY
  class APIClient
    class Resolver
      attr_reader :api

      def initialize(api)
        @api = api
      end

      def environment(options)
        raise ArgumentError if options[:app_name]
        candidates, account_candidates, app_candidates, environment_candidates = filter_candidates(options)

        environments = candidates.map{ |c| [c[:account_name], c[:environment_name]] }.uniq.map do |account_name, environment_name|
          api.environments.named(environment_name, account_name)
        end

        if environments.empty?
          if options[:environment_name]
            raise EY::NoEnvironmentError.new(options[:environment_name])
          else
            raise EY::NoAppError.new(options[:repo])
          end
        elsif environments.size > 1
          if options[:environment_name]
            message = "Multiple environments possible, please be more specific:\n\n"
            candidates.map{|e| [e[:account_name], e[:environment_name]]}.uniq.each do |account_name, environment_name|
              message << "\t#{environment_name.ljust(25)} # ey <command> --environment='#{environment_name}' --account='#{account_name}'\n"
            end
            raise MultipleMatchesError.new(message)
          else
            raise EY::AmbiguousEnvironmentGitUriError.new(environments)
          end
        end
        environments.first
      end

      def app_and_environment(options)
        candidates, account_candidates, app_candidates, environment_candidates = filter_candidates(options)

        if candidates.empty?
          if account_candidates.empty? && options[:account_name]
            raise NoMatchesError.new("There were no accounts that matched #{options[:account_name]}")
          elsif app_candidates.empty?
            if options[:app_name]
              raise InvalidAppError.new(options[:app_name])
            else
              raise NoAppError.new(options[:repo])
            end
          elsif environment_candidates.empty?
            raise NoEnvironmentError.new(options[:environment_name])
          else
            message = "The matched apps & environments do not correspond with each other.\n"
            message << "Applications:\n"
            app_candidates.map{|ad| [ad[:account_name], ad[:app_name]]}.uniq.each do |account_name, app_name|
              app = api.apps.named(app_name, account_name)
              message << "\t#{app.name}\n"
              app.environments.each do |env|
                message << "\t\t#{env.name} # ey <command> -e #{env.name} -a #{app.name}\n"
              end
            end
          end
          raise NoMatchesError.new(message)
        elsif candidates.size > 1
          message = "Multiple app deployments possible, please be more specific:\n\n"
          candidates.map{|c| [c[:account_name], c[:app_name]]}.uniq.each do |account_name, app_name|
            message << "#{app_name}\n"
            candidates.select {|c| c[:app_name] == app_name && c[:account_name] == account_name}.map{|c| c[:environment_name]}.uniq.each do |env_name|
              message << "\t#{env_name.ljust(25)} # ey <command> --environment='#{env_name}' --app='#{app_name}' --account='#{account_name}'\n"
            end
          end
          raise MultipleMatchesError.new(message)
        end
        result = candidates.first
        [api.apps.named(result[:app_name], result[:account_name]), api.environments.named(result[:environment_name], result[:account_name])]
      end

      private

      def app_environments
        @app_environments ||= api.apps.map do |app|
          app.environments.map do |environment|
            {
              :app_name => app.name.downcase,
              :repository_uri => app.repository_uri,
              :environment_name => environment.name.downcase,
              :account_name => app.account.name.downcase,
            }
          end
        end.flatten
      end

      def filter_candidates(options)
        raise ArgumentError if options.empty?

        candidates = app_environments

        account_candidates = filter_candidates_by(:account_name, options, candidates)

        app_candidates = if options[:app_name]
                           filter_candidates_by(:app_name, options, candidates)
                         elsif options[:repo]
                           filter_by_repo(candidates, options[:repo])
                         else
                           candidates
                         end

        environment_candidates = filter_candidates_by(:environment_name, options, candidates)
        candidates = app_candidates & environment_candidates & account_candidates
        [candidates, account_candidates, app_candidates, environment_candidates]
      end

      def filter_by_repo(candidates, repo)
        results = candidates.select do |candidate|
          repo.has_remote?(candidate[:repository_uri])
        end

        if results.empty?
          candidates
        else
          results
        end
      end

      def filter_candidates_by(type, options, candidates)
        if options[type] && candidates.any?{|c| c[type] == options[type].downcase }
          candidates.select {|c| c[type] == options[type].downcase }
        elsif options[type]
          candidates.select {|c| c[type][options[type].downcase] }
        else
          candidates
        end
      end
    end
  end
end
