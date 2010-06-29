require 'escape'

module EY
  module Model
    class Instance < ApiStruct.new(:id, :role, :name, :status, :amazon_id, :public_hostname, :environment)
      EYSD_VERSION = ENV["EY_DEPLOY_VERSION"] || "0.7.1"
      EXIT_STATUS = Hash.new { |h,k| raise EY::Error, "ey-deploy version checker exited with unknown status code #{k}" }
      EXIT_STATUS.merge!({
        255 => :ssh_failed,
        1   => :eysd_missing,
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

        invoke_eysd_deploy(deploy_args, verbose)
      end

      def rollback(app, extra_configuration=nil, verbose=false)
        deploy_args = ['rollback',
          '--app',   app.name,
          '--stack', environment.stack_name,
        ]

        if extra_configuration
          deploy_args << '--config' << extra_configuration.to_json
        end

        invoke_eysd_deploy(deploy_args, verbose)
      end


      def put_up_maintenance_page(app, verbose=false)
        invoke_eysd_deploy(['enable_maintenance_page', '--app', app.name], verbose)
      end

      def take_down_maintenance_page(app, verbose=false)
        invoke_eysd_deploy(['disable_maintenance_page', '--app', app.name], verbose)
      end


      def ensure_eysd_present
        case ey_deploy_check
        when :ssh_failed
          raise EnvironmentError, "SSH connection to #{hostname} failed"
        when :eysd_missing
          yield :installing if block_given?
          install_ey_deploy
        when :ok
          # no action needed
        else
          raise EY::Error, "Internal error: Unexpected status from Instance#ey_deploy_check; got #{eysd_status.inspect}"
        end
      end

      def ey_deploy_check
        escaped_eysd_version = EYSD_VERSION.gsub(/\./, '\.')

        if ENV["NO_SSH"]
          :ok
        else
          ssh "#{gem_path} list ey-deploy | grep \"ey-deploy \" | egrep -q '#{escaped_eysd_version}[,)]'", false
          EXIT_STATUS[$?.exitstatus]
        end
      end

      def install_ey_deploy
        ssh(Escape.shell_command([
              'sudo', 'sh', '-c',
              # rubygems looks at *.gem in its current directory for
              # installation candidates, so we have to make sure it
              # runs from a directory with no gem files in it.
              #
              # rubygems help suggests that --remote will disable this
              # behavior, but it doesn't.
              "cd `mktemp -d` && #{gem_path} install ey-deploy --no-rdoc --no-ri -v #{EYSD_VERSION}"]))
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

      def invoke_eysd_deploy(deploy_args, verbose=false)
        start = [eysd_path, "_#{EYSD_VERSION}_", 'deploy']
        instance_args = environment.instances.inject(['--instances']) do |command, inst|
          instance_tuple = [inst.public_hostname, inst.role]
          instance_tuple << inst.name if inst.name

          command << instance_tuple.join(',')
        end

        verbose_arg = verbose ? ['--verbose'] : []

        cmd = Escape.shell_command(start + deploy_args + instance_args + verbose_arg)
        puts cmd if verbose
        ssh cmd
      end

      def eysd_path
        "/usr/local/ey_resin/ruby/bin/eysd"
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
