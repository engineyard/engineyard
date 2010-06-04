require 'spec_helper'

describe "ey deploy without an eyrc file" do

  it_should_behave_like "an integration test without an eyrc file"

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
  it_should_behave_like "an integration test"

  context "with invalid input" do
    it "complains when there is no app" do
      api_scenario "empty"
      ey "deploy", :expect_failure => true
      @err.should include(%|no application configured|)
    end

    it "complains when you specify a nonexistent environment" do
      api_scenario "one app, one environment"
      ey "deploy typo-happens-here master", :expect_failure => true
      @err.should match(/no environment named 'typo-happens-here'/i)
    end

    it "complains when the specified environment does not contain the app" do
      api_scenario "one app, one environment, not linked"
      ey "deploy giblets master", :expect_failure => true
      @err.should match(/doesn't run this application/i)
    end

    it "complains when environment is not specified and app is in >1 environment" do
      api_scenario "one app, two environments"
      ey "deploy", :expect_failure => true
      @err.should match(/single environment.*2/i)
    end

    it "complains when the app master is in a non-running state" do
      api_scenario "one app, one environment, app master red"
      ey "deploy giblets master", :expect_failure => true
      @err.should_not match(/No running instances/i)
      @err.should match(/running.*\(green\)/)
    end
  end

  it "runs when environment is known" do
    api_scenario "one app, one environment"
    ey "deploy", :hide_err => true
    @out.should match(/running deploy/i)
    @err.should be_empty
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

    it "can be disabled with --no-migrate in the middle of the command line" do
      ey "deploy --no-migrate giblets master"
      @ssh_commands.last.should_not =~ /--migrate/
    end
  end

  context "choosing something to deploy" do
    before(:all) do
      api_scenario "one app, one environment", "user@git.host/path/to/repo.git"
    end

    before(:all) do
      @local_git_dir = File.join(
        Dir.tmpdir,
        "ey_test_git_#{Time.now.tv_sec}_#{Time.now.tv_usec}_#{$$}")

      Dir.mkdir(@local_git_dir)

      Dir.chdir(@local_git_dir) do
        [
          # initial repo setup
          'git init >/dev/null 2>&1',
          'git config user.email deploy@spec.test',
          'git config user.name "Deploy Spec"',
          'git remote add origin "user@git.host/path/to/repo.git"',

          # we'll have one commit on master
          "echo 'source :gemcutter' > Gemfile",
          "git add Gemfile",
          "git commit -m 'initial commit' >/dev/null 2>&1",

          # and a tag
          "git tag -a -m 'version one' v1",

          # and we need a non-master branch
          "git checkout -b current-branch >/dev/null 2>&1",
        ].each do |cmd|
          system("#{cmd}") or raise "#{cmd} failed"
        end
      end
    end

    before(:each) do
      @original_dir = Dir.getwd
      Dir.chdir(@local_git_dir)
    end

    after(:each) do
      Dir.chdir(@original_dir)
    end

    context "without a configured default branch" do
      it "defaults to the checked-out local branch" do
        ey "deploy"
        @ssh_commands.last.should =~ /--branch current-branch/
      end

      it "deploys another branch if given" do
        ey "deploy giblets master"
        @ssh_commands.last.should =~ /--branch master/
      end

      it "deploys a tag if given" do
        ey "deploy giblets v1"
        @ssh_commands.last.should =~ /--branch v1/
      end
    end

    context "when there is extra configuration" do
      before(:all) do
        write_yaml({"environments" => {"giblets" => {"bert" => "ernie"}}},
          File.join(@local_git_dir, "ey.yml"))
      end

      after(:all) do
        File.unlink(File.join(@local_git_dir, "ey.yml"))
      end

      it "gets passed along to eysd" do
        ey "deploy"
        @ssh_commands.last.should =~ /--config '\{\"bert\":\"ernie\"\}'/
      end
    end

    context "with a configured default branch" do
      before(:all) do
        write_yaml({"environments" => {"giblets" => {"branch" => "master"}}},
          File.join(@local_git_dir, "ey.yml"))
      end

      after(:all) do
        File.unlink(File.join(@local_git_dir, "ey.yml"))
      end

      it "deploys the default branch by default" do
        ey "deploy"
        @ssh_commands.last.should =~ /--branch master/
      end

      it "complains about a non-default branch without --force" do
        ey "deploy giblets current-branch", :expect_failure => true
        @err.should =~ /deploy branch is set to "master"/
      end

      it "deploys a non-default branch with --force" do
        ey "deploy giblets current-branch --force"
        @ssh_commands.last.should =~ /--branch current-branch/
      end
    end
  end

  context "specifying an environment" do
    before(:all) do
      api_scenario "one app, many similarly-named environments"
    end

    it "lets you choose by unambiguous substring" do
      ey "deploy prod"
      @out.should match(/Running deploy for 'railsapp_production'/)
    end

    it "lets you choose by complete name even if the complete name is ambiguous" do
      ey "deploy railsapp_staging"
      @out.should match(/Running deploy for 'railsapp_staging'/)
    end

    it "complains when given an ambiguous substring" do
      # NB: there's railsapp_staging and railsapp_staging_2
      ey "deploy staging", :hide_err => true, :expect_failure => true
      @err.should match(/'staging' is ambiguous/)
    end
  end

  context "eysd install" do
    before(:all) do
      api_scenario "one app, one environment"
    end

    before(:each) do
      ENV.delete "NO_SSH"
    end

    after(:each) do
      ENV['NO_SSH'] = "true"
    end

    def exiting_ssh(exit_code)
      "#!/usr/bin/env ruby\n exit!(#{exit_code}) if ARGV.to_s =~ /Base64.decode64/"
    end

    it "raises an error if SSH fails" do
      ey "deploy", :prepend_to_path => {'ssh' => exiting_ssh(255)}, :expect_failure => true
      @err.should =~ /SSH connection to \S+ failed/
    end

    it "installs ey-deploy if it's missing" do
      ey "deploy", :prepend_to_path => {'ssh' => exiting_ssh(104)}

      gem_install_command = @ssh_commands.find do |command|
        command =~ /gem install ey-deploy/
      end
      gem_install_command.should =~ %r{/usr/local/ey_resin/ruby/bin/gem install}
    end

    it "upgrades ey-deploy if it's too old" do
      ey "deploy", :prepend_to_path => {'ssh' => exiting_ssh(70)}
      @ssh_commands.should have_command_like(/gem uninstall -a -x ey-deploy/)
      @ssh_commands.should have_command_like(/gem install ey-deploy/)
    end

    it "raises an error if ey-deploy is too new" do
      ey "deploy", :prepend_to_path => {'ssh' => exiting_ssh(17)}, :expect_failure => true
      @ssh_commands.should_not have_command_like(/gem install ey-deploy/)
      @ssh_commands.should_not have_command_like(/eysd deploy/)
      @err.should match(/too new/i)
    end

    it "does not change ey-deploy if its version is satisfactory" do
      ey "deploy", :prepend_to_path => {'ssh' => exiting_ssh(0)}
      @ssh_commands.should_not have_command_like(/gem install ey-deploy/)
      @ssh_commands.should_not have_command_like(/gem uninstall.* ey-deploy/)
      @ssh_commands.should have_command_like(/eysd deploy/)
    end
  end
end
