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

    @out.should include("We need to fetch your API token, please login")
    @out.should include("Email:")
    @out.should include("Password:")
    @ssh_commands.should_not be_empty
  end
end


describe "ey deploy" do
  given "integration"

  def command_to_run(options)
    cmd = "deploy"
    cmd << " -e #{options[:env]}" if options[:env]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/Running deploy for '#{scenario[:environment]}'/)
  end

  # common behavior
  it_should_behave_like "it takes an environment name"
  it_should_behave_like "it invokes eysd"
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
      @err.should match(/does not run this application/i)
    end

    it "complains when environment is not specified and app is in >1 environment" do
      api_scenario "one app, two environments"
      ey "deploy", :expect_failure => true
      @err.should match(/single environment.*2/i)
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

    it "finds eysd despite its being buried in the filesystem" do
      ey "deploy"
      @ssh_commands.last.should =~ %r{/usr/local/ey_resin/ruby/bin/eysd}
    end

    it "defaults to 'rake db:migrate'" do
      ey "deploy"
      @ssh_commands.last.should =~ /eysd deploy/
      @ssh_commands.last.should =~ /--migrate 'rake db:migrate'/
    end

    it "can be disabled with --no-migrate" do
      ey "deploy --no-migrate"
      @ssh_commands.last.should =~ /eysd deploy/
      @ssh_commands.last.should_not =~ /--migrate/
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
        @ssh_commands.last.should =~ /--branch current-branch/
      end

      it "deploys another branch if given" do
        ey "deploy --ref master"
        @ssh_commands.last.should =~ /--branch master/
      end

      it "deploys a tag if given" do
        ey "deploy --ref v1"
        @ssh_commands.last.should =~ /--branch v1/
      end
    end

    context "when there is extra configuration" do
      before(:each) do
        write_yaml({"environments" => {"giblets" => {"bert" => "ernie"}}})
      end

      after(:each) do
        File.unlink("ey.yml")
      end

      it "gets passed along to eysd" do
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
        @ssh_commands.last.should =~ /--branch master/
      end

      it "complains about a non-default branch without --force" do
        ey "deploy -r current-branch", :expect_failure => true
        @err.should =~ /deploy branch is set to "master"/
      end

      it "deploys a non-default branch with --force" do
        ey "deploy -r current-branch --force"
        @ssh_commands.last.should =~ /--branch current-branch/
      end
    end
  end

  context "specifying an environment" do
    before(:all) do
      api_scenario "one app, many similarly-named environments"
    end

    it "lets you choose by complete name even if the complete name is ambiguous" do
      ey "deploy --environment railsapp_staging"
      @out.should match(/Running deploy for 'railsapp_staging'/)
    end
  end
end
