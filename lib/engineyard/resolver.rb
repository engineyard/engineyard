module EY
  class Resolver
    attr_reader :api
    
    def initialize(api)
      @api = api
    end

    def environment(options)
      raise ArgumentError if options[:app_name]
      candidates, app_candidates, environment_candidates = filter_candidates(options)

      environments = candidates.map{ |c| c[:environment_name] }.uniq.map do |environment_name|
        api.environments.named(environment_name)
      end

      if environments.empty?
        if options[:environment_name]
          raise EY::NoEnvironmentError.new(options[:environment_name])
        else
          raise EY::NoAppError.new(options[:repo])
        end
      elsif environments.size > 1
        if options[:environment_name]
          raise EY::AmbiguousEnvironmentNameError.new(options[:environment_name], environments)
        else
          raise EY::AmbiguousEnvironmentGitUriError.new(environments)
        end
      end

      environments.first
    end

    def app_and_environment(options)
      candidates, app_candidates, environment_candidates = filter_candidates(options)

      if candidates.empty?
        if app_candidates.empty?
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
          app_candidates.map{|ad| ad[:app_name]}.uniq.each do |app_name|
            app = api.apps.named(app_name)
            message << "\t#{app.name}\n"
            app.environments.each do |env|
              message << "\t\t#{env.name} # ey deploy -e #{env.name} -a #{app.name}\n"
            end
          end
        end
        raise NoMatchesError.new(message)
      elsif candidates.size > 1
        message = "Multiple app deployments possible, please be more specific:\n\n"
        candidates.map{|c| c[:app_name]}.uniq.each do |app_name|
          message << "#{app_name}\n"
          candidates.select {|x| x[:app_name] == app_name }.map{|x| x[:environment_name]}.uniq.each do |env_name|
            message << "\t#{env_name} # ey deploy -e #{env_name} -a #{app_name}\n"
          end
        end
        raise MultipleMatchesError.new(message)
      end
      [api.apps.named(candidates.first[:app_name]), api.environments.named(candidates.first[:environment_name])]
    end

    private

    def app_deployments
      @app_deployments ||= api.apps.map do |app|
        app.environments.map do |environment|
          { 
            :id => app.id * environment.id, 
            :app_name => app.name,
            :repository_uri => app.repository_uri,
            :environment_name => environment.name,
          }
        end
      end.flatten
    end

    def filter_candidates(options)
      raise ArgumentError if options.empty?

      candidates = app_deployments

      candidates = filter_candidates_by(:account, options, candidates)

      app_candidates = if options[:app_name]
                         filter_candidates_by(:app_name, options, candidates)
                       elsif options[:repo]
                         candidates.select {|c| options[:repo].urls.include?(c[:repository_uri]) }
                       else
                         candidates
                       end

      environment_candidates = filter_candidates_by(:environment_name, options, candidates)
      candidates = app_candidates & environment_candidates
      [candidates, app_candidates, environment_candidates]
    end

    def filter_candidates_by(type, options, candidates)
      if options[type] && candidates.any?{|c| c[type] == options[type] }
        candidates.select {|c| c[type] == options[type] }
      elsif options[type]
        candidates.select {|c| c[type][options[type]] }
      else
        candidates
      end
    end
  end
end
