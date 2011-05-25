require 'escape'
require 'net/ssh'

module EY
  module Model
    class Instance < ApiStruct.new(:id, :role, :name, :status, :amazon_id, :public_hostname, :environment)
      alias :hostname :public_hostname

      def adapter(app, verbose)
        require 'engineyard-serverside-adapter'
        EY::Serverside::Adapter.new("/usr/local/ey_resin/ruby/bin") do |args|
          args.app           = app.name
          args.repo          = app.repository_uri
          args.instances     = instances_data
          args.verbose       = verbose || ENV['DEBUG']
          args.stack         = environment.app_server_stack_name
          args.framework_env = environment.framework_env
        end
      end
      private :adapter

      def deploy(app, ref, migration_command=nil, extra_configuration=nil, verbose=false)
        successful, output = false, ""
        deployment = Deployment.started(environment, app, ref, migration_command)

        deploy_command = adapter(app, verbose).deploy do |args|
          args.config  = extra_configuration if extra_configuration
          args.migrate = migration_command if migration_command
          args.ref     = deployment.resolved_ref
        end

        successful = invoke(deploy_command) { |chunk| output << chunk }
      ensure
        if deployment
          deployment.finished(successful, output)
          EY.ui.info "#{successful ? 'Successful' : 'Failed'} deployment recorded in AppCloud"
        end
      end

      def rollback(app, extra_configuration=nil, verbose=false)
        rollback = adapter(app, verbose).rollback do |args|
          args.config = extra_configuration if extra_configuration
        end
        invoke rollback
      end


      def put_up_maintenance_page(app, verbose=false)
        invoke adapter(app, verbose).enable_maintenance_page
      end

      def take_down_maintenance_page(app, verbose=false)
        invoke adapter(app, verbose).disable_maintenance_page
      end

      def has_app_code?
        !["db_master", "db_slave"].include?(role.to_s)
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

      def ssh(remote_command, verbose, &block)
        raise(ArgumentError, "Block required!") unless block

        exit_code = nil
        cmd = Escape.shell_command(['bash', '-lc', remote_command])
        EY.ui.debug(cmd)
        puts cmd if verbose
        if ENV["NO_SSH"]
          block.call("NO_SSH is set. No output.")
          true
        else
          begin
            Net::SSH.start(hostname, environment.username, :paranoid => false) do |net_ssh|
              net_ssh.open_channel do |channel|
                channel.exec cmd do |_, success|
                  unless success
                    block.call "Remote command execution failed"
                    return false
                  end

                  channel.on_data do |_, data|
                    block.call data
                  end

                  channel.on_extended_data do |_, _, data|
                    block.call data
                  end

                  channel.on_request("exit-status") do |_, data|
                    exit_code = data.read_long
                  end

                  channel.on_request("exit-signal") do |_, data|
                    exit_code = 255
                  end
                end
              end

              net_ssh.loop
            end
            exit_code.zero?
          rescue Net::SSH::AuthenticationFailed
            raise EY::Error, "Authentication Failed: Please add your environment's ssh key with: ssh-add path/to/key"
          end
        end
      end

      def invoke(action, &block)
        action.call do |cmd|
          ssh cmd, action.verbose do |chunk|
            $stdout << chunk
            block.call(chunk) if block
          end
        end
      end

      def instances_data
        environment.instances.select { |inst| inst.has_app_code? }.map do |i|
          {
            :hostname => i.engineyard_serverside_hostname,
            :roles    => [i.role],
            :name     => i.name,
          }
        end
      end

      def app_master?
        environment.app_master == self
      end
    end
  end
end
