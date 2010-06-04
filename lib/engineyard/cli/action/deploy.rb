module EY
  class CLI
    module Action
      class Deploy

        EYSD_VERSION = "~>0.3.0"

        def self.call(env_name, branch, options)
          env_name ||= EY.config.default_environment

          app    = api.app_for_repo!(repo)
          env    = fetch_environment(env_name, app)
          branch = fetch_branch(env, branch, options[:force])
          master = env.app_master!

          EY.ui.info "Connecting to the server..."
          master.ensure_eysd_present! do |eysd_status|
            case eysd_status
            when :eysd_missing
              EY.ui.warn "Instance does not have server-side component installed"
              EY.ui.info "Installing server-side component..."
            when :too_old
              EY.ui.info "Upgrading server-side component..."
            else
              # nothing slow is happening, so there's nothing to say
            end
          end

          EY.ui.info "Running deploy for '#{env.name}' on server..."
          deployed = master.deploy!(app, branch, options[:migrate], env.config)

          if deployed
            EY.ui.info "Deploy complete"
          else
            raise EY::Error, "Deploy failed"
          end
        end

        private

        def self.api
          @api ||= EY::CLI::API.new
        end

        def self.repo
          @repo ||= EY::Repo.new
        end

        def self.fetch_environment(env_name, app)
          env = if env_name
                  app.environments.match_one(env_name)
                else
                  app.sole_environment!
                end

          # the environment exists, but doesn't have this app
          if !env && api.environments.named(env_name)
            raise EnvironmentError, "Environment '#{env_name}' doesn't run this application\nYou can add it at #{EY.config.endpoint}"
          end

          if !env
            raise NoEnvironmentError.new(env_name)
          end

          env
        end

        def self.fetch_branch(env, user_specified_branch, force)
          default_branch = env.default_branch

          branch = if user_specified_branch
                     if default_branch && (user_specified_branch != default_branch) && !force
                       raise BranchMismatch.new(default_branch, user_specified_branch)
                     end
                     user_specified_branch
                   else
                     default_branch || repo.current_branch
                   end

          raise DeployArgumentError unless branch
          branch
        end

      end
    end
  end
end
