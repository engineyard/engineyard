module EY
  class CLI
    module Action
      class Deploy

        EYSD_VERSION = "~>0.3.0"

        def self.call(env_name, branch, options)
          env_name ||= EY.config.default_environment

          app    = fetch_app
          env    = fetch_environment(env_name, app)
          branch = fetch_branch(env.name, branch, options[:force])
          master = env.app_master!

          EY.ui.info "Connecting to the server..."
          ensure_eysd_present(master, options[:install_eysd])

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

        def self.fetch_app
          app = api.app_for_repo(repo)
          raise NoAppError.new(repo) unless app
          app
        end

        def self.fetch_environment(env_name, app)
          # if the name's not specified and there's not exactly one
          # environment, we can't figure out which environment to deploy
          raise DeployArgumentError if !env_name && app.environments.size != 1

          env = if env_name
                  app.environments.match_one(env_name)
                else
                  app.environments.first
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

        def self.fetch_branch(env_name, user_specified_branch, force)
          default_branch = EY.config.default_branch(env_name)

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

        def self.ensure_eysd_present(instance, install_eysd)
          eysd_status = instance.ey_deploy_check
          case eysd_status
          when :ssh_failed
            raise EnvironmentError, "SSH connection to #{instance.hostname} failed"
          when :eysd_missing
            EY.ui.warn "Instance does not have server-side component installed"
            EY.ui.info "Installing server-side component..."
            instance.install_ey_deploy!
          when :too_new
            raise EnvironmentError, "server-side component too new; please upgrade your copy of the engineyard gem."
          when :too_old
            EY.ui.info "Upgrading server-side component..."
            instance.upgrade_ey_deploy!
          when :ok
            # no action needed
          else
            raise EY::Error, "Internal error: Unexpected status from Instance#ey_deploy_check; got #{eysd_status.inspect}"
          end
        end

      end
    end
  end
end
