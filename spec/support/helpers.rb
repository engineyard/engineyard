require 'engineyard/cli'

require 'realweb'
require 'rest_client'
require 'open4'
require 'stringio'

module SpecHelpers
  module Given
    def given(name)
      include_examples name
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

  module IntegrationHelpers
    def run_ey(command_options, ey_options={})
      if respond_to?(:extra_ey_options)   # needed for ssh tests
        ey_options.merge!(extra_ey_options)
      end

      ey(command_to_run(command_options), ey_options)
    end

    def make_scenario(hash)
      # since nil will silently turn to empty string when interpolated,
      # and there's a lot of string matching involved in integration
      # testing, it would be nice to have early notification of typos.
      scenario = Hash.new { |h,k| raise "Tried to get key #{k.inspect}, but it's missing!" }
      scenario.merge!(hash)
    end
  end

  module GitRepoHelpers
    def define_git_repo(name, &setup)
      # EY's ivars don't get cleared between examples, so we can keep
      # a git repo around longer (and thus make our tests faster)
      EY.define_git_repo(name, &setup)
    end

    def use_git_repo(repo_name)
      before(:all) do
        @_original_wd ||= []
        @_original_wd << Dir.getwd
        Dir.chdir(EY.git_repo_dir(repo_name))
      end

      after(:all) do
        Dir.chdir(@_original_wd.pop)
      end
    end
  end

  class UnexpectedExit < StandardError
    def initialize(stdout, stderr)
      super "Exited with an unexpected exit code\n---STDOUT---\n#{stdout}\n---STDERR---\n#{stderr}\n"
    end
  end
  NonzeroExitStatus = Class.new(UnexpectedExit)
  ZeroExitStatus = Class.new(UnexpectedExit)

  def ey_api
    @api ||= EY::APIClient.new('asdf')
  end

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
    rescue EY::Error, EY::APIClient::Error => e
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

    ey_env = {
      'DEBUG'     => 'true',
      'EYRC'      => ENV['EYRC'],
      'CLOUD_URL' => ENV['CLOUD_URL'],
    }

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

  def read_yaml(file)
    YAML.load(File.read(File.expand_path(file)))
  end

  def write_yaml(data, file)
    File.open(file, "w"){|f| YAML.dump(data, f) }
  end

  def read_eyrc
    read_yaml(ENV['EYRC'])
  end

  def write_eyrc(data)
    write_yaml(data, ENV['EYRC'])
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
