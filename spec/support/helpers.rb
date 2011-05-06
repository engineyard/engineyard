require 'engineyard/cli'

require 'realweb'
require 'rest_client'
require 'open4'
require 'stringio'

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

    def fast_ey(args)
      err, out = StringIO.new, StringIO.new
      capture_stderr_into(err) do
        capture_stdout_into(out) do
          with_env('DEBUG' => 'true') do
            EY::CLI.start(args)
          end
        end
      end
    ensure
      @err, @out = err.string, out.string
      @raw_ssh_commands, @ssh_commands = extract_ssh_commands(@out)
    end

    def fast_failing_ey(*args)
      begin
        fast_ey(*args)
        raise ZeroExitStatus.new(@out, @err)
      rescue SystemExit => exit_status
        # SystemExit typically indicates a bogus command, which we
        # here in expected-to-fail land are entirely happy with.
        nil
      rescue EY::Error => e
        more_err, more_out = StringIO.new, StringIO.new

        capture_stderr_into(more_err) do
          capture_stdout_into(more_out) do
            EY.ui.print_exception(e)
          end
        end

        @err << more_err.string
        @out << more_out.string
      end
    end

    def capture_stderr_into(stream)
      $stderr = stream
      yield
    ensure
      $stderr = STDERR
    end

    def capture_stdout_into(stream)
      $stdout = stream
      yield
    ensure
      $stdout = STDOUT
    end

    def ey(args = [], options = {}, &block)
      hide_err = options.has_key?(:hide_err) ? options[:hide_err] : options[:expect_failure]
      path_prepends = options[:prepend_to_path]

      ey_env = {'DEBUG' => 'true'}
      if options.has_key?(:debug)
        ey_env['DEBUG'] = options[:debug] ? "true" : nil
      end

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
        exit_status = Open4::open4("#{eybin} #{Escape.shell_command(args)}") do |pid, stdin, stdout, stderr|
          block.call(stdin) if block
          @out = stdout.read
          @err = stderr.read
        end

        if !exit_status.success? && !options[:expect_failure]
          raise NonzeroExitStatus.new(@out, @err)
        elsif exit_status.success? && options[:expect_failure]
          raise ZeroExitStatus.new(@out, @err)
        end
      end

      @raw_ssh_commands, @ssh_commands = extract_ssh_commands(@out)

      puts @err unless @err.empty? || hide_err
      @out
    end

    def extract_ssh_commands(output)
      raw_ssh_commands = @out.split(/\n/).find_all do |line|
        line =~ /^bash -lc/ || line =~ /^ssh/
      end

      ssh_commands = raw_ssh_commands.map do |cmd|
        # Strip off everything up to and including user@host, leaving
        # just the command that the remote system would run
        #
        # XXX: this is a really icky icky.
        # engineyard gem was written as if shelling out to run serverside
        # and running an ssh command will always be the same. This is a nasty
        # hack to get it working with Net::SSH for now so we can repair 1.9.2.
        ssh_prefix_removed = cmd.gsub(/^bash -lc /, '').gsub(/^ssh .*?\w+@\S*\s*/, '')

        # Its arguments have been double-escaped: one layer is to get
        # them through our local shell and into ssh, and the other
        # layer is to get them through the remote system's shell.
        #
        # Strip off one layer by running it through the shell.
        just_the_remote_command = ssh_prefix_removed.gsub(/>\s*\/dev\/null.*$/, '')
        `echo #{just_the_remote_command}`.strip
      end

      [raw_ssh_commands, ssh_commands]
    end

    def api_scenario(scenario, remote = "user@git.host:path/to/repo.git")
      response = ::RestClient.put(EY.fake_awsm + '/scenario', {"scenario" => scenario, "remote" => remote}, {})
      raise "Setting scenario failed: #{response.inspect}" unless response.code == 200
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

module Spec
  module Helpers
    module SemanticNames

      def given(name)
        it_should_behave_like name
      end

    end

    module Fixtures
      def fixture_recipes_tgz
        File.expand_path('../fixture_recipes.tgz', __FILE__)
      end

      def link_recipes_tgz(git_dir)
        system("ln -s #{fixture_recipes_tgz} #{git_dir.join('recipes.tgz')}")
      end
    end
  end
end

module EY
  class << self
    def fake_awsm
      @fake_awsm ||= begin
        config_ru = File.join(EY_ROOT, "spec/support/fake_awsm.ru")
        unless system("ruby -c '#{config_ru}' > /dev/null")
          raise SyntaxError, "There is a syntax error in fake_awsm.ru! fix it!"
        end
        @server = RealWeb.start_server_in_fork(config_ru)
        "http://localhost:#{@server.port}"
      end
    end
    alias_method :start_fake_awsm, :fake_awsm

    def define_git_repo(name, &setup)
      @git_repo_setup ||= {}
      return if @git_repo_setup.key?(name)
      @git_repo_setup[name] = setup
    end

    def refresh_git_repo(name)
      @git_repo_dir_cache ||= {}
      @git_repo_dir_cache.delete name
    end

    def git_repo_dir(name)
      @git_repo_dir_cache ||= {}
      return @git_repo_dir_cache[name] if @git_repo_dir_cache.has_key?(name)
      raise ArgumentError, "No definition for git repo #{name}" unless @git_repo_setup[name]

      git_dir = Pathname.new("/tmp/engineyard_test_repo_#{Time.now.tv_sec}_#{Time.now.tv_usec}_#{$$}")
      git_dir.mkdir
      Dir.chdir(git_dir) do
        system("git init -q")
        system('git config user.email ey@spec.test')
        system('git config user.name "EY Specs"')
        system("git remote add testremote user@git.host:path/to/repo.git")
        @git_repo_setup[name].call(git_dir)
      end
      @git_repo_dir_cache[name] = git_dir
    end
  end
end
