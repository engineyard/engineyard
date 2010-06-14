require 'escape'

module EY
  module Model
    class Instance < ApiStruct.new(:id, :role, :status, :amazon_id, :public_hostname, :environment)
      EYSD_VERSION = "~>0.4.0"
      CHECK_SCRIPT = <<-SCRIPT
require "rubygems"
requirement = Gem::Requirement.new("#{EYSD_VERSION}")
required_version = requirement.requirements.last.last # thanks thanks rubygems rubygems

# this will be a ["name-version", Gem::Specification] two-element array if present, nil otherwise
ey_deploy_geminfo = Gem.source_index.find{ |(name,_)| name =~ /^ey-deploy-\\\d/ }
exit(104) unless ey_deploy_geminfo

current_version = ey_deploy_geminfo.last.version
exit(0) if requirement.satisfied_by?(current_version)
exit(70) if required_version > current_version
exit(17) # required_version < current_version
      SCRIPT
      EXIT_STATUS = Hash.new { |h,k| raise EY::Error, "ey-deploy version checker exited with unknown status code #{k}" }
      EXIT_STATUS.merge!({
        255 => :ssh_failed,
        104 => :eysd_missing,
        70  => :too_old,
        17  => :too_new,
        0   => :ok,
      })

      alias :hostname :public_hostname


      def deploy(app, ref, migration_command=nil, extra_configuration=nil)
        deploy_cmd = [eysd_path, 'deploy', '--app', app.name, '--branch', ref]

        if extra_configuration
          deploy_cmd << '--config' << extra_configuration.to_json
        end

        if migration_command
          deploy_cmd << "--migrate" << migration_command
        end

        ssh Escape.shell_command(deploy_cmd)
      end

      def rollback(app, extra_configuration=nil)
        deploy_cmd = [eysd_path, 'deploy', 'rollback', '--app', app.name]

        if extra_configuration
          deploy_cmd << '--config' << extra_configuration.to_json
        end

        ssh Escape.shell_command(deploy_cmd)
      end


      def put_up_maintenance_page(app)
        ssh Escape.shell_command([
            eysd_path, 'deploy', 'enable_maintenance_page', '--app', app.name
          ])
      end

      def take_down_maintenance_page(app)
        ssh Escape.shell_command([
            eysd_path, 'deploy', 'disable_maintenance_page', '--app', app.name
          ])
      end


      def ensure_eysd_present
        case ey_deploy_check
        when :ssh_failed
          raise EnvironmentError, "SSH connection to #{hostname} failed"
        when :eysd_missing
          yield :installing if block_given?
          install_ey_deploy
        when :too_new
          raise EnvironmentError, "server-side component too new; please upgrade your copy of the engineyard gem."
        when :too_old
          yield :upgrading if block_given?
          upgrade_ey_deploy
        when :ok
          # no action needed
        else
          raise EY::Error, "Internal error: Unexpected status from Instance#ey_deploy_check; got #{eysd_status.inspect}"
        end
      end

      def ey_deploy_check
        require 'base64'
        encoded_script = Base64.encode64(CHECK_SCRIPT).gsub(/\n/, '')
        ssh "#{ruby_path} -r base64 -e \"eval Base64.decode64(ARGV[0])\" #{encoded_script}", false
        EXIT_STATUS[$?.exitstatus]
      end

      def install_ey_deploy
        ssh(Escape.shell_command(['sudo', gem_path, 'install', 'ey-deploy', '-v', EYSD_VERSION]))
      end

      def upgrade_ey_deploy
        ssh "sudo #{gem_path} uninstall -a -x ey-deploy"
        install_ey_deploy
      end

    private

      def ssh(remote_command, output = true)
        user = environment.username

        cmd = Escape.shell_command(%w[ssh -o StrictHostKeyChecking=no -q] << "#{user}@#{hostname}" << remote_command)
        cmd << " > /dev/null" unless output
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

      def ruby_path
        "/usr/local/ey_resin/ruby/bin/ruby"
      end

    end
  end
end
