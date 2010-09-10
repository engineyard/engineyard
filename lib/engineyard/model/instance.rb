require 'escape'

module EY
  module Model
    class Instance < ApiStruct.new(:id, :role, :name, :status, :amazon_id, :public_hostname, :environment)
      EXIT_STATUS = Hash.new { |h,k| raise EY::Error, "engineyard-serverside version checker exited with unknown status code #{k}" }
      EXIT_STATUS.merge!({
        255 => :ssh_failed,
        1   => :engineyard_serverside_missing,
        0   => :ok,
      })

      alias :hostname :public_hostname


      def deploy(app, ref, migration_command=nil, extra_configuration=nil, verbose=false)
        deploy_args = [
          '--app',    app.name,
          '--repo',   app.repository_uri,
          '--stack',  environment.stack_name,
          '--branch', ref,
        ]

        if extra_configuration
          deploy_args << '--config' << extra_configuration.to_json
        end

        if migration_command
          deploy_args << "--migrate" << migration_command
        end

        invoke_engineyard_serverside(deploy_args, verbose)
      end

      def rollback(app, extra_configuration=nil, verbose=false)
        deploy_args = ['rollback',
          '--app',   app.name,
          '--stack', environment.stack_name,
        ]

        if extra_configuration
          deploy_args << '--config' << extra_configuration.to_json
        end

        invoke_engineyard_serverside(deploy_args, verbose)
      end


      def put_up_maintenance_page(app, verbose=false)
        invoke_engineyard_serverside(['enable_maintenance_page', '--app', app.name], verbose)
      end

      def take_down_maintenance_page(app, verbose=false)
        invoke_engineyard_serverside(['disable_maintenance_page', '--app', app.name], verbose)
      end


      def has_app_code?
        !["db_master", "db_slave"].include?(role.to_s)
      end

      def ensure_engineyard_serverside_present
        case engineyard_serverside_status = engineyard_serverside_check
        when :ssh_failed
          raise EnvironmentError, "SSH connection to #{hostname} failed"
        when :engineyard_serverside_missing
          yield :installing if block_given?
          install_engineyard_serverside
        when :ok
          # no action needed
        else
          raise EY::Error, "Internal error: Unexpected status from Instance#engineyard_serverside_check; got #{engineyard_serverside_status.inspect}"
        end
      end

      def engineyard_serverside_check
        escaped_engineyard_serverside_version = ENGINEYARD_SERVERSIDE_VERSION.gsub(/\./, '\.')

        if ENV["NO_SSH"]
          :ok
        else
          ssh "#{gem_path} list engineyard-serverside | grep \"engineyard-serverside\" | egrep -q '#{escaped_engineyard_serverside_version}[,)]'", false
          EXIT_STATUS[$?.exitstatus]
        end
      end

      def install_engineyard_serverside
        ssh(Escape.shell_command([
              'sudo', 'sh', '-c',
              # rubygems looks at *.gem in its current directory for
              # installation candidates, so we have to make sure it
              # runs from a directory with no gem files in it.
              #
              # rubygems help suggests that --remote will disable this
              # behavior, but it doesn't.
              "cd `mktemp -d` && #{gem_path} install engineyard-serverside --no-rdoc --no-ri -v #{ENGINEYARD_SERVERSIDE_VERSION}"]))
      end

    protected

      def engineyard_serverside_hostname
        # If we tell engineyard-serverside to use 'localhost', it'll run
        # commands on the instance directly (#system). If we give it the
        # instance's actual hostname, it'll SSH to itself.
        #
        # Using 'localhost' instead of its EC2 hostname speeds up
        # deploys on solos and single-app-server clusters significantly.
        app_master? ? 'localhost' : hostname
      end

    private

      def ssh(remote_command, output = true)
        user = environment.username

        cmd = Escape.shell_command(%w[ssh -o StrictHostKeyChecking=no -q] << "#{user}@#{hostname}" << remote_command)
        cmd << " > /dev/null" unless output
        EY.ui.debug(cmd)
        unless ENV["NO_SSH"]
          system cmd
        else
          true
        end
      end

      def invoke_engineyard_serverside(deploy_args, verbose=false)
        start = [engineyard_serverside_path, "_#{ENGINEYARD_SERVERSIDE_VERSION}_", 'deploy']

        instances = environment.instances.select { |inst| inst.has_app_code? }
        instance_args = ['']
        if !instances.empty?
          instance_args << '--instances'
          instance_args += instances.collect { |i| i.engineyard_serverside_hostname }

          instance_args << '--instance-roles'
          instance_args += instances.collect { |i| [i.engineyard_serverside_hostname, i.role].join(':') }

          instance_args << '--instance-names'
          instance_args += instances.collect { |i| i.name ? [i.engineyard_serverside_hostname, i.name].join(':') : nil }.compact
        end

        framework_arg = ['--framework-env', environment.framework_env]

        verbose_arg = (verbose || ENV['DEBUG']) ? ['--verbose'] : []

        cmd = Escape.shell_command(start + deploy_args + framework_arg + instance_args + verbose_arg)
        puts cmd if verbose
        ssh cmd
      end

      def engineyard_serverside_path
        "/usr/local/ey_resin/ruby/bin/engineyard-serverside"
      end

      def app_master?
        environment.app_master == self
      end

      def gem_path
        "/usr/local/ey_resin/ruby/bin/gem"
      end

      def ruby_path
        "/usr/local/ey_resin/ruby/bin/ruby"
      end

    end
  end
end
