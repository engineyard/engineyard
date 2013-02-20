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

  module IntegrationHelpers
    def run_ey(command_options, ey_options={})

      if respond_to?(:extra_ey_options)   # needed for ssh tests
        ey_options.merge!(extra_ey_options)
        return ey(command_to_run(command_options), ey_options)
      end

      if ey_options[:expect_failure]
        fast_failing_ey(command_to_run(command_options))
      else
        fast_ey(command_to_run(command_options))
      end
    end

    def make_scenario(opts)
      # since nil will silently turn to empty string when interpolated,
      # and there's a lot of string matching involved in integration
      # testing, it would be nice to have early notification of typos.
      scenario = Hash.new { |h,k| raise "Tried to get key #{k.inspect}, but it's missing!" }
      scenario.merge!(opts)
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
        EY.chdir_to_repo(repo_name)
      end

      after(:all) do
        EY.chdir_return
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
    @api ||= EY::CloudClient.new(:token => 'asdf')
  end

  def ensure_eyrc
    begin
      unless (data = read_eyrc) and data['api_token']
        raise ".eyrc has no token, specs will stall waiting for stdin authentication input"
      end
    rescue Errno::ENOENT => e
      raise ".eyrc must be written before calling run_ey or specs will stall waiting for stdin authentication input"
    end
  end

  def fast_ey(args, options = {})

    ensure_eyrc

    begin
      debug = options[:debug] ? 'true' : nil
      err, out = StringIO.new, StringIO.new
      capture_stderr_into(err) do
        capture_stdout_into(out) do
          with_env('DEBUG' => debug, 'PRINT_CMD' => 'true') do
            EY::CLI.start(args)
          end
        end
      end
    ensure
      @err, @out = err.string, out.string
      @raw_ssh_commands, @ssh_commands = extract_ssh_commands(@out)
    end
  end

  def fast_failing_ey(*args)
    begin
      fast_ey(*args)
      raise ZeroExitStatus.new(@out, @err)
    rescue SystemExit => exit_status
      # SystemExit typically indicates a bogus command, which we
      # here in expected-to-fail land are entirely happy with.
      nil
    rescue EY::Error, EY::CloudClient::Error => e
      nil
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
    if respond_to?(:extra_ey_options)   # needed for ssh tests
      options.merge!(extra_ey_options)
    end

    hide_err = options.has_key?(:hide_err) ? options[:hide_err] : options[:expect_failure]

    path_prepends = options[:prepend_to_path]

    ey_env = {
      'DEBUG'     => ENV['DEBUG'],
      'PRINT_CMD' => 'true',
      'EYRC'      => ENV['EYRC'],
      'CLOUD_URL' => ENV['CLOUD_URL'],
    }

    if options.has_key?(:debug)
      ey_env['DEBUG'] = options[:debug] ? "true" : nil
    end

    if path_prepends
      tempdir = TMPDIR.join("ey_test_cmds_#{Time.now.tv_sec}#{Time.now.tv_usec}_#{$$}")
      tempdir.mkpath
      path_prepends.each do |name, contents|
        tempdir.join(name).open('w') do |f|
          f.write(contents)
          f.chmod(0755)
        end
      end

      ey_env['PATH'] = "#{tempdir}:#{ENV['PATH']}"
    end

    eybin = File.expand_path('../bundled_ey', __FILE__)

    with_env(ey_env) do
      exit_status = Open4::open4("#{eybin} #{Escape.shell_command(args)}") do |pid, stdin, stdout, stderr|
        block.call(stdin) if block
        stdin.close
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
    raw_ssh_commands = [@out,@err].join("\n").split(/\n/).find_all do |line|
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

  DEPRECATED_SCENARIOS = {
    "empty"                                               => "User Name",
    "one app without environment"                         => "App Without Env",
    "one app, one environment, not linked"                => "Unlinked App",
    "two apps"                                            => "Two Apps",
    "one app, one environment"                            => "Linked App",
    "Stuck Deployment"                                    => "Stuck Deployment",
    "two accounts, two apps, two environments, ambiguous" => "Multiple Ambiguous Accounts",
    "one app, one environment, no instances"              => "Linked App Not Running",
    "one app, one environment, app master red"            => "Linked App Red Master",
    "one app, many environments"                          => "One App Many Envs",
    "one app, many similarly-named environments"          => "One App Similarly Named Envs",
    "two apps, same git uri"                              => "Two Apps Same Git URI",
  }

  def api_scenario(old_name)
    clean_eyrc # switching scenarios, always clean up
    name = DEPRECATED_SCENARIOS[old_name]
    @scenario = EY::CloudClient::Test::Scenario[name]
    @scenario_email     = @scenario.email
    @scenario_password  = @scenario.password
    @scenario_api_token = @scenario.api_token
    @scenario
  end

  def login_scenario(scenario_name)
    scen = api_scenario(scenario_name)
    write_eyrc('api_token' => scenario_api_token)
    scen
  end

  def scenario_email
    @scenario_email
  end

  def scenario_password
    @scenario_password
  end

  def scenario_api_token
    @scenario_api_token
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
      ENV[k] = v if v
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
