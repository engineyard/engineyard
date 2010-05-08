require 'engineyard/action/util'

module EY
  module Action
    class Deploy
      extend Util

      EYSD_VERSION = "~>0.2.7"

      def self.call(env_name, branch, options)
        env_name ||= EY.config.default_environment

        app = fetch_app
        env = fetch_environment(env_name, app)
        branch = fetch_branch(env.name, branch, options[:force])

        running = env.app_master && env.app_master.status == "running"
        raise EnvironmentError, "No running instances for environment #{env.name}\nStart one at #{EY.config.endpoint}" unless running

        hostname = env.app_master.public_hostname
        username = env.username

        EY.ui.info "Connecting to the server..."
        ensure_eysd_present(hostname, username, options[:install_eysd])

        deploy_cmd = "#{eysd_path} deploy --app #{app.name} --branch #{branch}"
        if env.config
          escaped_config_option = env.config.to_json.gsub(/"/, "\\\"")
          deploy_cmd << " --config '#{escaped_config_option}'"
        end

        if options['migrate']
          deploy_cmd << " --migrate='#{options[:migrate]}'"
        end

        EY.ui.info "Running deploy on server..."
        deployed = ssh_to(hostname, deploy_cmd, username)

        if deployed
          EY.ui.info "Deploy complete"
        else
          raise EY::Error, "Deploy failed"
        end
      end

    private

      def self.fetch_app
        app = account.app_for_repo(repo)
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
        if !env && account.environment_named(env_name)
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

      def self.ensure_eysd_present(hostname, username, install_eysd)
        ssh_to(hostname, "#{eysd_path} check '#{EY::VERSION}' '#{EYSD_VERSION}'", username, false)
        case $?.exitstatus
        when 255
          raise EnvironmentError, "SSH connection to #{hostname} failed"
        when 127
          EY.ui.warn "Server does not have ey-deploy gem installed"
          eysd_installed = false
        when 0
          eysd_installed = true
        else
          raise EnvironmentError, "ey-deploy version not compatible"
        end

        if !eysd_installed || install_eysd
          EY.ui.info "Installing ey-deploy gem..."
          ssh_to(hostname,
            "sudo #{gem_path} install ey-deploy -v '#{EYSD_VERSION}'",
            username)
        end
      end

      def self.eysd_path
        "/usr/local/ey_resin/ruby/bin/eysd"
      end

      def self.gem_path
        "/usr/local/ey_resin/ruby/bin/gem"
      end

      def self.ssh_to(hostname, remote_cmd, user, output = true)
        cmd = %{ssh -o StrictHostKeyChecking=no -q #{user}@#{hostname} "#{remote_cmd}"}
        cmd << %{ &> /dev/null} unless output
        output ? puts(cmd) : EY.ui.debug(cmd)
        unless ENV["NO_SSH"]
          system cmd
        else
          true
        end
      end

    end
  end
end
