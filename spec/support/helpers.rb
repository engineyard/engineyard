require 'realweb'
require "rest_client"
require 'open4'

module Spec
  module Helpers
    class UnexpectedExit < StandardError
      def initialize(stdout, stderr)
        @stdout, @stderr = stdout, stderr
      end

      def message
        "Exited with an unexpected exit code\n---STDOUT---\n#{@stdout}\n---STDERR---\n#{@stderr}\n"
      end
    end
    NonzeroExitStatus = Class.new(UnexpectedExit)
    ZeroExitStatus = Class.new(UnexpectedExit)

    def ey(cmd = nil, options = {}, &block)
      require "open3"
      hide_err = options.delete(:hide_err)
      path_prepends = options.delete(:prepend_to_path)

      ey_env = {
        'DEBUG' => options[:debug].to_s
      }

      if path_prepends
        tempdir = File.join(Dir.tmpdir, "ey_test_cmds_#{Time.now.tv_sec}#{Time.now.tv_usec}_#{$$}")
        Dir.mkdir(tempdir)
        path_prepends.each do |name, contents|
          File.open(File.join(tempdir, name), 'w') do |f|
            f.write(contents)
            f.chmod(0755)
          end
        end

        ey_env['PATH'] = tempdir + ':' + ENV['PATH']
      end

      eybin = File.expand_path('../bundled_ey', __FILE__)

      with_env(ey_env) do
        exit_status = Open4::open4("#{eybin} #{cmd}") do |pid, stdin, stdout, stderr|
          block.call(stdin) if block
          @err = stderr.read_available_bytes
          @out = stdout.read_available_bytes
        end

        if !exit_status.success? && !options[:expect_failure]
          raise NonzeroExitStatus.new(@out, @err)
        elsif exit_status.success? && options[:expect_failure]
          raise ZeroExitStatus.new(@out, @err)
        end
      end

      @ssh_commands = @out.split(/\n/).find_all do |line|
        line =~ /^ssh/
      end.map do |line|
        line.sub(/^.*?\"/, '').sub(/\"$/, '')
      end

      puts @err unless @err.empty? || hide_err
      @out
    end

    def api_scenario(scenario)
      response = ::RestClient.put(EY.fake_awsm + '/scenario', {"scenario" => scenario}, {})
      raise "Setting scenario failed: #{response.inspect}" unless response.code == 200
    end

    def api_git_remote(remote)
      response = ::RestClient.put(EY.fake_awsm + '/git_remote', {"remote" => remote}, {})
      raise "Setting git remote failed: #{response.inspect}" unless response.code == 200
    end

    def read_yaml(file="ey.yml")
      YAML.load_file(File.expand_path(file))
    end

    def write_yaml(data, file = "ey.yml")
      File.open(file, "w"){|f| YAML.dump(data, f) }
    end

    def with_env(new_env_vars)
      raise ArgumentError, "with_env takes a block" unless block_given?
      old_env_vars = {}
      new_env_vars.each do |k, v|
        if ENV.has_key?(k)
          old_env_vars[k] = ENV[k]
        end
        ENV[k] = v
      end

      retval = yield

      new_env_vars.keys.each do |k|
        if old_env_vars.has_key?(k)
          ENV[k] = old_env_vars[k]
        else
          ENV.delete(k)
        end
      end
      retval
    end
  end
end

module EY
  class << self
    def fake_awsm
      @fake_awsm ||= begin
        unless system("ruby -c spec/support/fake_awsm.ru > /dev/null")
          raise SyntaxError, "There is a syntax error in fake_awsm.ru! fix it!"
        end
        config_ru = File.join(EY_ROOT, "spec/support/fake_awsm.ru")
        @server = RealWeb.start_server(config_ru)
        "http://localhost:#{@server.port}"
      end
    end
    alias_method :start_fake_awsm, :fake_awsm
  end
end
