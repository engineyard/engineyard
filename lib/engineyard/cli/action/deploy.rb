require 'engineyard/action/util'

module EY
  class CLI
    module Action
      class Deploy
        extend EY::Action::Util

        EYSD_VERSION = "~>0.3.0"

        def self.call(env_name, branch, options)
          env_name ||= EY.config.default_environment

          app = fetch_app
          env = fetch_environment(env_name, app)
          branch = fetch_branch(env.name, branch, options[:force])

          running = env.app_master && env.app_master.status == "running"
          raise EnvironmentError, "No running instances for environment #{env.name}\nStart one at #{EY.config.endpoint}" unless running

          master   = env.app_master

          EY.ui.info "Connecting to the server..."
          ensure_eysd_present(master, options[:install_eysd])

          EY.ui.info "Running deploy on server..."
          deployed = master.deploy!(app, branch, options[:migrate], env.config)

          if deployed
            EY.ui.info "Deploy complete"
          else
            raise EY::Error, "Deploy failed"
          end
        end

        private

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
                  # environment names are unique per-customer, so
                  # there's no danger of finding two here
                  app.environments.find{|e| e.name == env_name }
                else
                  app.environments.first
                end

          # the environment exists, but doesn't have this app
          if !env && api.environment_named(env_name)
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
          ey_deploy_check = instance.ey_deploy_check

          if ey_deploy_check.ssh_failed?
            raise EnvironmentError, "SSH connection to #{instance.hostname} failed"
          end

          if ey_deploy_check.incompatible_version?
            raise EnvironmentError, "ey-deploy version not compatible"
          end

          if ey_deploy_check.missing?
            EY.ui.warn "Server does not have ey-deploy gem installed"
          end

          if ey_deploy_check.missing? || install_eysd
            EY.ui.info "Installing ey-deploy gem..."
            instance.install_ey_deploy!
          end
        end

      end
    end
  end
end
