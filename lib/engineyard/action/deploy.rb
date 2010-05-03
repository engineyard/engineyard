require 'engineyard/action/util'

module EY
  module Action
    class Deploy
      extend Util

      EYSD_VERSION = "~>0.2.6"

      def self.call(env_name, branch, options)
        app = account.app_for_repo(repo)
        raise NoAppError.new(repo) unless app

        env_name ||= EY.config.default_environment
        raise DeployArgumentError if !env_name && app.environments.size != 1

        default_branch = EY.config.default_branch(env_name)
        branch ||= (default_branch || repo.current_branch)
        raise DeployArgumentError unless branch

        invalid_branch = default_branch && (branch != default_branch) && !options[:force]
        raise BranchMismatch.new(default_branch, branch) if invalid_branch

        if env_name && app.environments
          env = app.environments.find{|e| e.name == env_name }
        else
          env = app.environments.first
        end

        if !env && account.environment_named(env_name)
          raise EnvironmentError, "Environment '#{env_name}' doesn't run this application\nYou can add it at #{EY.config.endpoint}"
        elsif !env
          raise NoEnvironmentError
        end

        running = env.app_master && env.app_master.status == "running"
        raise EnvironmentError, "No running instances for environment #{env.name}\nStart one at #{EY.config.endpoint}" unless running

        hostname = env.app_master.public_hostname
        username = env.username

        EY.ui.info "Connecting to the server..."
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

        if !eysd_installed || options[:install_eysd]
          EY.ui.info "Installing ey-deploy gem..."
          ssh_to(hostname,
            "sudo #{gem_path} install ey-deploy -v '#{EYSD_VERSION}'",
            username)
        end

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
