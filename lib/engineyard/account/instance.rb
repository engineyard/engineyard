require 'escape'

module EY
  class Account
    class Instance < ApiStruct.new(:id, :role, :status, :amazon_id, :public_hostname, :environment)
      EYSD_VERSION = "~>0.3.0"

      alias :hostname :public_hostname

      def deploy!(app, ref, migration_command=nil, extra_configuration=nil)
        deploy_cmd = [eysd_path, 'deploy', '--app', app.name, '--branch', ref]

        if extra_configuration
          deploy_cmd << '--config' << extra_configuration.to_json
        end

        if migration_command
          deploy_cmd << "--migrate" << migration_command
        end

        ssh Escape.shell_command(deploy_cmd)
      end

      def ey_deploy_check
        ssh(Escape.shell_command([eysd_path, 'check', EY::VERSION, EYSD_VERSION]),
          false)
        case $?.exitstatus
        when 255
          EysdCheck.new(:ssh_failed)
        when 127
          EysdCheck.new(:eysd_missing)
        when 0
          EysdCheck.new(:ok)
        else
          EysdCheck.new(:incompatible_version)
        end
      end

      def install_ey_deploy!
        ssh(Escape.shell_command(['sudo', gem_path, 'install', 'ey-deploy', '-v', EYSD_VERSION]))
      end

    private

      def ssh(remote_command, output = true)
        user = environment.username

        cmd = Escape.shell_command(%w[ssh -o StrictHostKeyChecking=no -q] << "#{user}@#{hostname}" << remote_command)
        cmd << "> /dev/null" unless output
        output ? puts(cmd) : EY.ui.debug(cmd)
        unless ENV["NO_SSH"]
          system cmd
        else
          true
        end
      end

      def eysd_path
        "/usr/local/ey_resin/ruby/bin/eysd"
      end

      def gem_path
        "/usr/local/ey_resin/ruby/bin/gem"
      end

      class EysdCheck < Struct.new(:status)
        def ssh_failed?
          status == :ssh_failed
        end

        def incompatible_version?
          status == :incompatible_version
        end

        def missing?
          status == :eysd_missing
        end
      end

    end
  end
end
