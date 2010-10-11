require 'spec_helper'

describe "ey deploy without an eyrc file" do

  given "integration without an eyrc file"

  before(:each) do
    FileUtils.rm_rf(ENV['EYRC'])
    api_scenario "one app, one environment"
  end

  it "prompts for authentication before continuing" do
    ey("deploy", :hide_err => true) do |input|
      input.puts("test@test.test")
      input.puts("test")
    end

    @out.should include("We need to fetch your API token; please log in.")
    @out.should include("Email:")
    @out.should include("Password:")
    @ssh_commands.should_not be_empty
  end
end


describe "ey deploy" do
  given "integration"

  def command_to_run(opts)
    cmd = "deploy"
    cmd << " --environment #{opts[:environment]}" if opts[:environment]
    cmd << " --app #{opts[:app]}" if opts[:app]
    cmd << " --account #{opts[:account]}" if opts[:account]
    cmd << " --ref #{opts[:ref]}" if opts[:ref]
    cmd << " --verbose" if opts[:verbose]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/Beginning deploy for.*#{scenario[:application]}.*#{scenario[:environment]}/)
    @ssh_commands.should have_command_like(/engineyard-serverside.*deploy.*--app #{scenario[:application]}/)
  end

  # common behavior
  it_should_behave_like "it takes an environment name and an app name and an account name"
  it_should_behave_like "it invokes engineyard-serverside"
end

describe "ey deploy" do
  given "integration"

  context "with invalid input" do
    it "complains when there is no app" do
      api_scenario "empty"
      ey "deploy", :expect_failure => true
      @err.should include(%|no application configured|)
    end

    it "complains when the specified environment does not contain the app" do
      api_scenario "one app, one environment, not linked"
      ey "deploy -e giblets -r master", :expect_failure => true
      @err.should match(/there is no application configured/i)
    end

    it "complains when environment is not specified and app is in >1 environment" do
      api_scenario "one app, many environments"
      ey "deploy", :expect_failure => true
      @err.should match(/multiple app deployments possible/i)
    end

    it "complains when the app master is in a non-running state" do
      api_scenario "one app, one environment, app master red"
      ey "deploy --environment giblets --ref master", :expect_failure => true
      @err.should_not match(/No running instances/i)
      @err.should match(/running.*\(green\)/)
    end
  end

  context "migration command" do
    before(:each) do
      api_scenario "one app, one environment"
    end

    it "finds engineyard-serverside despite its being buried in the filesystem" do
      ey "deploy"
      @ssh_commands.last.should =~ %r{/usr/local/ey_resin/ruby/bin/engineyard-serverside}
    end

    it "defaults to 'rake db:migrate'" do
      ey "deploy"
      @ssh_commands.last.should =~ /engineyard-serverside.*deploy/
      @ssh_commands.last.should =~ /--migrate 'rake db:migrate --trace'/
    end

    it "can be disabled with --no-migrate" do
      ey "deploy --no-migrate"
      @ssh_commands.last.should =~ /engineyard-serverside.*deploy/
      @ssh_commands.last.should_not =~ /--migrate/
    end

    it "uses the default when --migrate is specified with no value" do
      ey "deploy --migrate"
      @ssh_commands.last.should match(/--migrate 'rake db:migrate --trace'/)
    end

    context "customized in ey.yml" do
      before { write_yaml({"environments" => {"giblets" => {
                "migration_command" => 'thor fancy:migrate',
              }}}) }
      after  { File.unlink 'ey.yml' }

      it "migrates with the custom command by default" do
        ey "deploy"
        @ssh_commands.last.should =~ /--migrate 'thor fancy:migrate'/
      end
    end

    context "disabled in ey.yml" do
      before { write_yaml({"environments" => {"giblets" => {"migrate" => false}}}) }
      after  { File.unlink 'ey.yml' }

      it "does not migrate by default" do
        ey "deploy"
        @ssh_commands.last.should =~ /engineyard-serverside.*deploy/
        @ssh_commands.last.should_not =~ /--migrate/
      end

      it "can be turned back on with --migrate" do
        ey "deploy --migrate 'rake fancy:migrate'"
        @ssh_commands.last.should =~ /--migrate 'rake fancy:migrate'/
      end

      it "migrates with the default when --migrate is specified with no value" do
        ey "deploy --migrate"
        @ssh_commands.last.should match(/--migrate 'rake db:migrate --trace'/)
      end
    end

    context "explicitly enabled in ey.yml (the default)" do
      before { write_yaml({"environments" => {"giblets" => {"migrate" => true}}}) }
      after  { File.unlink 'ey.yml' }

      it "migrates with the default" do
        ey "deploy"
        @ssh_commands.last.should match(/--migrate 'rake db:migrate --trace'/)
      end
    end

    context "customized and disabled in ey.yml" do
      before { write_yaml({"environments" => {"giblets" => {
                "migrate" => false,
                "migration_command" => "thor fancy:migrate",
              }}}) }
      after  { File.unlink 'ey.yml' }

      it "does not migrate by default" do
        ey "deploy"
        @ssh_commands.last.should_not match(/--migrate/)
      end

      it "migrates with the custom command when --migrate is specified with no value" do
        ey "deploy --migrate"
        @ssh_commands.last.should match(/--migrate 'thor fancy:migrate'/)
      end
    end
  end

  context "the --framework-env option" do
    before(:each) do
      api_scenario "one app, one environment"
    end

    it "passes the framework environment" do
      ey "deploy"
      @ssh_commands.last.should match(/--framework-env production/)
    end
  end

  context "choosing something to deploy" do
    define_git_repo('deploy test') do
      # we'll have one commit on master
      system("echo 'source :gemcutter' > Gemfile")
      system("git add Gemfile")
      system("git commit -m 'initial commit' >/dev/null 2>&1")

      # and a tag
      system("git tag -a -m 'version one' v1")

      # and we need a non-master branch
      system("git checkout -b current-branch >/dev/null 2>&1")
    end

    use_git_repo('deploy test')

    before(:all) do
      api_scenario "one app, one environment", "user@git.host:path/to/repo.git"
    end

    context "without a configured default branch" do
      it "defaults to the checked-out local branch" do
        ey "deploy"
        @ssh_commands.last.should =~ /--ref current-branch/
      end

      it "deploys another branch if given" do
        ey "deploy --ref master"
        @ssh_commands.last.should =~ /--ref master/
      end

      it "deploys a tag if given" do
        ey "deploy --ref v1"
        @ssh_commands.last.should =~ /--ref v1/
      end

      it "allows using --branch to specify a branch" do
        ey "deploy --branch master"
        @ssh_commands.last.should match(/--ref master/)
      end

      it "allows using --tag to specify the tag" do
        ey "deploy --tag v1"
        @ssh_commands.last.should match(/--ref v1/)
      end
    end

    context "when there is extra configuration" do
      before(:each) do
        write_yaml({"environments" => {"giblets" => {"bert" => "ernie"}}})
      end

      after(:each) do
        File.unlink("ey.yml")
      end

      it "gets passed along to engineyard-serverside" do
        ey "deploy"
        @ssh_commands.last.should =~ /--config '\{\"bert\":\"ernie\"\}'/
      end
    end

    context "with a configured default branch" do
      before(:each) do
        write_yaml({"environments" => {"giblets" => {"branch" => "master"}}})
      end

      after(:each) do
        File.unlink "ey.yml"
      end

      it "deploys the default branch by default" do
        ey "deploy"
        @ssh_commands.last.should =~ /--ref master/
      end

      it "complains about a non-default branch without --ignore-default_branch" do
        ey "deploy -r current-branch", :expect_failure => true
        @err.should =~ /deploy branch is set to "master"/
      end

      it "deploys a non-default branch with --ignore-default-branch" do
        ey "deploy -r current-branch --ignore-default-branch"
        @ssh_commands.last.should =~ /--ref current-branch/
      end
    end
  end

  context "specifying an environment" do
    before(:all) do
      api_scenario "one app, many similarly-named environments"
    end

    it "lets you choose by complete name even if the complete name is ambiguous" do
      ey "deploy --environment railsapp_staging"
      @out.should match(/Beginning deploy for.*'railsapp_staging'/)
    end
  end

  context "--extra-deploy-hook-options" do
    before(:all) do
      api_scenario "one app, one environment"
    end

    def extra_deploy_hook_options
      if @ssh_commands.last =~ /--config (.*?)(?: -|$)/
        # the echo strips off the layer of shell escaping, leaving us
        # with pristine JSON
        JSON.parse `echo #{$1}`
      end
    end

    it "passes the extra configuration to engineyard-serverside" do
      ey "deploy --extra-deploy-hook-options some:stuff more:crap"
      extra_deploy_hook_options.should_not be_nil
      extra_deploy_hook_options['some'].should == 'stuff'
      extra_deploy_hook_options['more'].should == 'crap'
    end

    context "when ey.yml is present" do
      before do
        write_yaml({"environments" => {"giblets" => {"beer" => "stout"}}})
      end

      after { File.unlink("ey.yml") }

      it "overrides what's in ey.yml" do
        ey "deploy --extra-deploy-hook-options beer:esb"
        extra_deploy_hook_options['beer'].should == 'esb'
      end
    end
  end

  context "specifying the application" do
    before(:all) do
      api_scenario "one app, one environment"
    end

    before(:each) do
      @_deploy_spec_start_dir = Dir.getwd
      Dir.chdir(File.expand_path("~"))
    end

    after(:each) do
      Dir.chdir(@_deploy_spec_start_dir)
    end

    it "allows you to specify an app when not in a directory" do
      ey "deploy --app rails232app --ref master"
      @ssh_commands.last.should match(/--app rails232app/)
      @ssh_commands.last.should match(/--ref master/)
    end

    it "requires that you specify a ref when specifying the application" do
      Dir.chdir(File.expand_path("~")) do
        ey "deploy --app rails232app", :expect_failure => true
        @err.should match(/you must also specify the ref to deploy/)
      end
    end
  end

  context "sending necessary information" do
    use_git_repo("deploy test")

    before(:all) do
      api_scenario "one app, one environment", "user@git.host:path/to/repo.git"
      ey "deploy"
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
