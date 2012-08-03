require 'escape'
require 'net/ssh'
require 'engineyard-serverside-adapter'

module EY
  class ServersideRunner
    def initialize(bridge, app, environment, verbose)
      @verbose = verbose || ENV['DEBUG']
      @adapter = load_adapter(bridge, app, environment)
      @username = environment.username
      @hostname = bridge
      @command = nil
    end

    def deploy(&block)
      @command = @adapter.deploy(&block)
      self
    end

    def rollback(&block)
      @command = @adapter.rollback(&block)
      self
    end

    def put_up_maintenance_page(&block)
      @command = @adapter.enable_maintenance(&block)
      self
    end

    def take_down_maintenance_page(&block)
      @command = @adapter.disable_maintenance(&block)
      self
    end

    def call(out, err)
      raise "No command!" unless @command
      @command.call do |cmd|
        run cmd, out, err
      end
    end

  private

    def load_adapter(bridge, app, environment)
      EY::Serverside::Adapter.new("/usr/local/ey_resin/ruby/bin") do |args|
        args.app              = app.name
        args.repo             = app.repository_uri
        args.instances        = instances_data(environment.deploy_to_instances, bridge)
        args.stack            = environment.app_server_stack_name
        args.framework_env    = environment.framework_env
        args.environment_name = environment.name
        args.account_name     = app.account.name
        args.verbose          = @verbose
      end
    end

    # If we tell engineyard-serverside to use 'localhost', it'll run
    # commands on the instance directly (#system). If we give it the
    # instance's actual hostname, it'll SSH to itself.
    #
    # Using 'localhost' instead of its EC2 hostname speeds up
    # deploys on solos and single-app-server clusters significantly.
    def instances_data(instances, bridge)
      instances.map do |i|
        {
          :hostname => i.hostname == bridge ? 'localhost' : i.hostname,
          :roles    => [i.role],
          :name     => i.name,
        }
      end
    end

    def run(remote_command, out, err)
      cmd = Escape.shell_command(['bash', '-lc', remote_command])

      if cmd.respond_to?(:encoding) && cmd.respond_to?(:force_encoding)
        out << "Encoding: #{cmd.encoding.name}" if @verbose
        cmd.force_encoding('binary')
        out << " => #{cmd.encoding.name}; __ENCODING__: #{__ENCODING__.name}; LANG: #{ENV['LANG']}; LC_CTYPE: #{ENV['LC_CTYPE']}\n" if @verbose
      end

      out << "Running command on #{@username}@#{@hostname}.\n"
      out << cmd << "\n" if @verbose

      if ENV["NO_SSH"]
        out << "NO_SSH is set. No output.\n"
        true
      else
        begin
          ssh(cmd, @hostname, @username, out, err)
        rescue Net::SSH::AuthenticationFailed
          raise EY::Error, "Authentication Failed: Please add your environment's ssh key with: ssh-add path/to/key"
        end
      end
    end

    def net_ssh_options
      level = :fatal # default in Net::SSH
      if debug = ENV["DEBUG"]
        level = :info
        if %w[debug info warn error fatal].include?(debug.downcase)
          level = debug.downcase.to_sym
        end
      end
      {:paranoid => false, :verbose => level}
    end

    def ssh(cmd, hostname, username, out, err)
      exit_code = 1
      Net::SSH.start(hostname, username, net_ssh_options) do |net_ssh|
        net_ssh.open_channel do |channel|
          channel.exec cmd do |_, success|
            unless success
              err << "Remote command execution failed"
              return false
            end

            channel.on_data do |_, data|
              out << data
            end

            channel.on_extended_data do |_, _, data|
              err << data
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
    end

  end
end
