require 'spec_helper'

describe "ey deploy without an eyrc file" do
  given "integration"

  it "prompts for authentication before continuing" do
    api_scenario "one app, one environment"

    ey(%w[deploy --no-migrate], :hide_err => true) do |input|
      input.puts(scenario_email)
      input.puts(scenario_password)
    end

    @out.should include("We need to fetch your API token; please log in.")
    @out.should include("Email:")
    @out.should include("Password:")
    @ssh_commands.should_not be_empty

    read_eyrc.should == {"api_token" => scenario_api_token}
  end

  it "uses the token on the command line" do
    api_scenario "one app, one environment"
    ey(%w[deploy --no-migrate --api-token] + [scenario_api_token])
    @ssh_commands.should_not be_empty
  end
end


describe "ey deploy" do
  given "integration"

  def command_to_run(opts)
    cmd = ["deploy"]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--app"         << opts[:app]         if opts[:app]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd << "--ref"         << opts[:ref]         if opts[:ref]
    cmd << "--migrate"                           if opts[:migrate]
    cmd                    << opts[:migrate]     if opts[:migrate].respond_to?(:str)
    cmd << "--no-migrate"                        if opts[:migrate] == nil
    cmd << "--verbose"                           if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/Beginning deploy.../)
    @out.should match(/Application:\s+#{scenario[:application]}/)
    @out.should match(/Environment:\s+#{scenario[:environment]}/)
    @out.should match(/deployment recorded/i)
    @ssh_commands.should have_command_like(/engineyard-serverside.*deploy.*--app #{scenario[:application]}/)
  end

  # common behavior
  include_examples "it takes an environment name and an app name and an account name"
  include_examples "it invokes engineyard-serverside"
end

describe "ey deploy" do
  given "integration"

  context "without ssh keys (with ssh enabled)" do
    before do
      ENV.delete('NO_SSH')
      Net::SSH.stub!(:start).and_raise(Net::SSH::AuthenticationFailed.new("no key"))
    end

    after do
      ENV['NO_SSH'] = 'true'
    end

    it "tells you that you need to add an appropriate ssh key (even with --quiet)" do
      login_scenario "one app, one environment"
      fast_failing_ey %w[deploy --no-migrate --quiet]
      @err.should include("Authentication Failed")
    end
  end

  context "with invalid input" do
    it "complains when there is no app" do
      login_scenario "empty"
      fast_failing_ey ["deploy"]
      @err.should include(%|No application found|)
    end

    it "complains when the specified environment does not contain the app" do
      login_scenario "one app, one environment, not linked"
      fast_failing_ey %w[deploy -e giblets -r master]
      @err.should match(/Application "rails232app" and environment "giblets" are not associated./)
    end

    it "complains when environment is not specified and app is in >1 environment" do
      login_scenario "one app, many environments"
      fast_failing_ey %w[deploy --ref master --no-migrate]
      @err.should match(/Multiple application environments possible/i)
    end

    it "complains when the app master is in a non-running state" do
      login_scenario "one app, one environment, app master red"
      fast_failing_ey %w[deploy --environment giblets --ref master --no-migrate]
      @err.should_not match(/No running instances/i)
      @err.should match(/running.*\(green\)/)
    end
  end

  context "migration command" do
    before(:each) do
      login_scenario "one app, one environment"
    end

    it "finds engineyard-serverside despite its being buried in the filesystem" do
      fast_ey %w[deploy --no-migrate]
      @ssh_commands.last.should =~ %r{/usr/local/ey_resin/ruby/bin/engineyard-serverside}
    end

    context "without migrate sepecified, interactively reads migration command" do
      def clean_ey_yml
        File.unlink 'ey.yml' if File.exist?('ey.yml')
        FileUtils.rm_r 'config' if FileTest.exist?('config')
      end

      before { clean_ey_yml }
      after  { clean_ey_yml }

      it "defaults to yes, and then rake db:migrate (and installs to config/ey.yml if config/ exists already)" do
        ey_yml = Pathname.new('config/ey.yml')
        File.exist?('ey.yml').should be_false
        ey_yml.dirname.mkpath
        ey_yml.should_not be_exist
        ey(%w[deploy]) do |input|
          input.puts('')
          input.puts('')
        end
        @ssh_commands.last.should =~ /engineyard-serverside.*deploy/
        @ssh_commands.last.should =~ /--migrate 'rake db:migrate'/
        File.exist?('ey.yml').should be_false
        ey_yml.should be_exist
        env_conf = read_yaml(ey_yml.to_s)['defaults']
        env_conf['migrate'].should == true
        env_conf['migration_command'].should == 'rake db:migrate'
      end

      it "accepts new commands" do
        File.exist?('ey.yml').should be_false
        FileTest.exist?('config').should be_false
        ey(%w[deploy], :hide_err => true) do |input|
          input.puts("y")
          input.puts("ruby migrate")
        end
        @ssh_commands.last.should =~ /engineyard-serverside.*deploy/
        @ssh_commands.last.should =~ /--migrate 'ruby migrate'/
        File.exist?('ey.yml').should be_true
        env_conf = read_yaml('ey.yml')['defaults']
        env_conf['migrate'].should == true
        env_conf['migration_command'].should == 'ruby migrate'
      end

      it "doesn't ask for the command if you say no" do
        File.exist?('ey.yml').should be_false
        ey(%w[deploy], :hide_err => true) do |input|
          input.puts("no")
        end
        @ssh_commands.last.should =~ /engineyard-serverside.*deploy/
        @ssh_commands.last.should_not =~ /--migrate/
        File.exist?('ey.yml').should be_true
        read_yaml('ey.yml')['defaults']['migrate'].should == false
      end
    end

    it "can be disabled with --no-migrate" do
      fast_ey %w[deploy --no-migrate]
      @ssh_commands.last.should =~ /engineyard-serverside.*deploy/
      @ssh_commands.last.should_not =~ /--migrate/
    end

    it "uses the default when --migrate is specified with no value" do
      fast_ey %w[deploy --migrate]
      @ssh_commands.last.should match(/--migrate 'rake db:migrate'/)
    end

    context "customized in ey.yml with defaults" do
      before { write_yaml({"defaults" => { "migration_command" => "thor fancy:migrate"}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "migrates with the custom command by default (and fixes ey.yml to reflect the previous default behavior)" do
        fast_ey %w[deploy]
        @ssh_commands.last.should =~ /--migrate 'thor fancy:migrate'/
        read_yaml('ey.yml')['defaults']['migrate'].should == true
      end
    end

    context "customized in ey.yml with environment specific options overriding the defaults" do
      before do
        write_yaml({
          "defaults" => { "migration_command" => "rake plain:migrate"},
          "environments" => {"giblets" => { "migration_command" => 'thor fancy:migrate' }}
        }, 'ey.yml')
      end
      after  { File.unlink 'ey.yml' }

      it "migrates with the custom command by default (and fixes ey.yml for the specific environment to reflect the previous default behavior)" do
        fast_ey %w[deploy]
        @ssh_commands.last.should =~ /--migrate 'thor fancy:migrate'/
        read_yaml('ey.yml')['defaults']['migrate'].should == true
      end
    end

    context "disabled in ey.yml" do
      before { write_yaml({"environments" => {"giblets" => {"migrate" => false}}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "does not migrate by default" do
        fast_ey %w[deploy]
        @ssh_commands.last.should =~ /engineyard-serverside.*deploy/
        @ssh_commands.last.should_not =~ /--migrate/
      end

      it "can be turned back on with --migrate" do
        fast_ey ["deploy", "--migrate", "rake fancy:migrate"]
        @ssh_commands.last.should =~ /--migrate 'rake fancy:migrate'/
      end

      it "migrates with the default when --migrate is specified with no value" do
        fast_ey %w[deploy --migrate]
        @ssh_commands.last.should match(/--migrate 'rake db:migrate'/)
      end
    end

    context "explicitly enabled in ey.yml (the default)" do
      before { write_yaml({"environments" => {"giblets" => {"migrate" => true}}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "migrates with the default (and writes the default to ey.yml)" do
        fast_ey %w[deploy]
        @ssh_commands.last.should match(/--migrate 'rake db:migrate'/)
        read_yaml('ey.yml')['defaults']['migration_command'].should == 'rake db:migrate'
      end
    end

    context "customized and disabled in ey.yml" do
      before { write_yaml({"environments" => {"giblets" => { "migrate" => false, "migration_command" => "thor fancy:migrate" }}}, 'ey.yml') }
      after  { File.unlink 'ey.yml' }

      it "does not migrate by default" do
        fast_ey %w[deploy]
        @ssh_commands.last.should_not match(/--migrate/)
      end

      it "migrates with the custom command when --migrate is specified with no value" do
        fast_ey %w[deploy --migrate]
        @ssh_commands.last.should match(/--migrate 'thor fancy:migrate'/)
      end
    end
  end

  context "the --framework-env option" do
    before(:each) do
      login_scenario "one app, one environment"
    end

    it "passes the framework environment" do
      fast_ey %w[deploy --no-migrate]
      @ssh_commands.last.should match(/--framework-env production/)
    end
  end

  context "choosing something to deploy" do
    use_git_repo('deploy test')

    before(:all) do
      login_scenario "one app, one environment"
    end

    context "without a configured default branch" do
      it "defaults to the checked-out local branch" do
        fast_ey %w[deploy --no-migrate]
        @ssh_commands.last.should =~ /--ref resolved-current-branch/
      end

      it "deploys another branch if given" do
        fast_ey %w[deploy --ref master --no-migrate]
        @ssh_commands.last.should =~ /--ref resolved-master/
      end

      it "deploys a tag if given" do
        fast_ey %w[deploy --ref v1 --no-migrate]
        @ssh_commands.last.should =~ /--ref resolved-v1/
      end

      it "allows using --branch to specify a branch" do
        fast_ey %w[deploy --branch master --no-migrate]
        @ssh_commands.last.should match(/--ref resolved-master/)
      end

      it "allows using --tag to specify the tag" do
        fast_ey %w[deploy --tag v1 --no-migrate]
        @ssh_commands.last.should match(/--ref resolved-v1/)
      end
    end

    context "when there is extra configuration" do
      before(:each) do
        write_yaml({"environments" => {"giblets" => {"bert" => "ernie"}}}, 'ey.yml')
      end

      after(:each) do
        File.unlink("ey.yml")
      end

      it "no longer gets passed along to engineyard-serverside (since serverside will read it on its own)" do
        fast_ey %w[deploy --no-migrate]
        @ssh_commands.last.should_not =~ /"bert":"ernie"/
      end
    end

    context "with a configured default branch" do
      before(:each) do
        write_yaml({"environments" => {"giblets" => {"branch" => "master", "migrate" => false}}}, 'ey.yml')
      end

      after(:each) do
        File.unlink "ey.yml"
      end

      it "deploys the default branch by default" do
        fast_ey %w[deploy]
        @ssh_commands.last.should =~ /--ref resolved-master/
      end

      it "complains about a non-default branch without --ignore-default-branch" do
        fast_failing_ey %w[deploy -r current-branch]
        @err.should =~ /default branch is set to "master"/
      end

      it "deploys a non-default branch with --ignore-default-branch" do
        fast_ey %w[deploy -r current-branch --ignore-default-branch]
        @ssh_commands.last.should =~ /--ref resolved-current-branch/
      end

      it "deploys a non-default branch with --R ref" do
        fast_ey %w[deploy -R current-branch]
        @ssh_commands.last.should =~ /--ref resolved-current-branch/
      end
    end
  end

  context "specifying an environment" do
    before(:all) do
      login_scenario "one app, many similarly-named environments"
    end

    it "lets you choose by complete name even if the complete name is ambiguous" do
      fast_ey %w[deploy --environment railsapp_staging --no-migrate]
      @out.should match(/Beginning deploy.../)
      @out.should match(/Ref:\s+master/)
      @out.should match(/Environment:\s+railsapp_staging/)
    end
  end

  context "--config (--extra-deploy-hook-options)" do
    before(:all) do
      login_scenario "one app, one environment"
    end

    def config_options
      if @ssh_commands.last =~ /--config (.*?)(?: -|$)/
        # the echo strips off the layer of shell escaping, leaving us
        # with pristine JSON
        MultiJson.load `echo #{$1}`
      end
    end

    it "passes --config to engineyard-serverside" do
      ey %w[deploy --config some:stuff more:crap --no-migrate]
      config_options.should_not be_nil
      config_options['some'].should == 'stuff'
      config_options['more'].should == 'crap'
    end

    it "supports legacy --extra-deploy-hook-options" do
      ey %w[deploy --extra-deploy-hook-options some:stuff more:crap --no-migrate]
      config_options.should_not be_nil
      config_options['some'].should == 'stuff'
      config_options['more'].should == 'crap'
    end

    context "when ey.yml is present" do
      before do
        write_yaml({"environments" => {"giblets" => {"beer" => "stout", "migrate" => true}}}, 'ey.yml')
      end

      after { File.unlink("ey.yml") }

      it "overrides what's in ey.yml" do
        fast_ey %w[deploy --config beer:esb]
        config_options['beer'].should == 'esb'
      end
    end
  end

  context "specifying the application" do
    before(:all) do
      login_scenario "one app, one environment"
    end

    before(:each) do
      @_deploy_spec_start_dir = Dir.getwd
      Dir.chdir(File.expand_path("~"))
    end

    after(:each) do
      Dir.chdir(@_deploy_spec_start_dir)
    end

    it "allows you to specify an app when not in a directory" do
      fast_ey %w[deploy --app rails232app --ref master --migrate]
      @ssh_commands.last.should match(/--app rails232app/)
      @ssh_commands.last.should match(/--ref resolved-master/)
      @ssh_commands.last.should match(/--migrate 'rake db:migrate'/)
    end

    it "requires that you specify a ref when specifying the application" do
      Dir.chdir(File.expand_path("~")) do
        fast_failing_ey %w[deploy --app rails232app --no-migrate]
        @err.should match(/you must also specify the --ref/)
      end
    end

    it "requires that you specify a migrate option when specifying the application" do
      Dir.chdir(File.expand_path("~")) do
        fast_failing_ey %w[deploy --app rails232app --ref master]
        @err.should match(/you must also specify .* --migrate or --no-migrate/)
      end
    end
  end

  context "setting a specific serverside version" do
    use_git_repo("deploy test")

    before(:all) do
      login_scenario "one app, one environment"
    end

    it "should send the correct serverside version when specified" do
      fast_ey %w[deploy --no-migrate --serverside-version 1.6.4]
      deploy_command = @ssh_commands.find {|c| c =~ /engineyard-serverside.*deploy/ }
      deploy_command.should =~ /engineyard-serverside _1.6.4_ deploy/
    end

    it "should send the default serverside version when unspecified" do
      fast_ey %w[deploy --no-migrate]
      deploy_command = @ssh_commands.find {|c| c =~ /engineyard-serverside.*deploy/ }
      deploy_command.should =~ /engineyard-serverside _#{EY::ENGINEYARD_SERVERSIDE_VERSION}_ deploy/
    end
  end

  context "sending necessary information" do
    use_git_repo("deploy test")

    before(:all) do
      login_scenario "one app, one environment"
      fast_ey %w[deploy --no-migrate]
      @deploy_command = @ssh_commands.find {|c| c =~ /engineyard-serverside.*deploy/ }
    end

    it "passes along the repository URL to engineyard-serverside" do
      @deploy_command.should =~ /--repo user@git.host:path\/to\/repo.git/
    end

    it "passes along the web server stack to engineyard-serverside" do
      @deploy_command.should =~ /--stack nginx_mongrel/
    end
  end

end
