require 'escape'
require 'open4'

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
          args.stack         = environment.stack_name
          args.framework_env = environment.framework_env
        end
      end
      private :adapter

      def deploy(app, ref, migration_command=nil, extra_configuration=nil, verbose=false)
        deployment = Deployment.started(environment, app, ref, migration_command)

        deploy_command = adapter(app, verbose).deploy do |args|
          args.config  = extra_configuration if extra_configuration
          args.migrate = migration_command if migration_command
          args.ref     = ref
        end

        successful, output = invoke_with_output(deploy_command)
        deployment.finished(successful, output)
        successful
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

      def ssh(remote_command)
        user = environment.username
        out = ""
        handler = lambda do |chunk|
          out << chunk
          $stdout << chunk
        end

        cmd = Escape.shell_command(%w[ssh -o StrictHostKeyChecking=no -q] << "#{user}@#{hostname}" << remote_command)
        EY.ui.debug(cmd)
        if ENV["NO_SSH"]
          [true, "NO_SSH is set."]
        else
          status = Open4.spawn(cmd, :out => handler, :err => handler, :quiet => true)
          [status.success?, out]
        end
      end

      def invoke(action)
        invoke_with_output(action).first
      end

      def invoke_with_output(action)
        action.call do |cmd|
          puts cmd if action.verbose
          ssh cmd
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
