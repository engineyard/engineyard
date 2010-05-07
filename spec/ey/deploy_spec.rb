require 'spec_helper'

describe "ey deploy" do
  # like the "an integration test" setup, but without the ~/.eyrc file
  # so we can test creating it
  before(:all) do
    FakeFS.deactivate!
    ENV['EYRC'] = "/tmp/eyrc"
    ENV['CLOUD_URL'] = EY.fake_awsm
    FakeWeb.allow_net_connect = true
  end

  after(:all) do
    ENV['CLOUD_URL'] = nil
    FakeFS.activate!
    FakeWeb.allow_net_connect = false
  end

  describe "without an eyrc file" do
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
end

describe "ey deploy" do
  it_should_behave_like "an integration test"

  context "with invalid input" do
    it "complains when there is no app" do
      api_scenario "empty"
      ey "deploy", :hide_err => true, :expect_failure => true
      @err.should include(%|no application configured|)
    end

    it "complains when you specify a nonexistent environment" do
      api_scenario "one app, one environment"
      ey "deploy typo-happens-here master", :hide_err => true, :expect_failure => true
      @err.should match(/no environment named 'typo-happens-here'/i)
    end

    it "complains when the specified environment does not contain the app" do
      api_scenario "one app, one environment, not linked"
      ey "deploy giblets master", :hide_err => true, :expect_failure => true
      @err.should match(/doesn't run this application/i)
    end

    it "complains when environment is ambiguous" do
      api_scenario "one app, two environments"
      ey "deploy", :hide_err => true, :expect_failure => true
      @err.should match(/was called incorrectly/i)
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
      @ssh_commands.last.should =~ /--migrate='rake db:migrate'/
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

    it "can be disabled with --no-migrate" do
      ey "deploy --no-migrate"
      @ssh_commands.last.should =~ /eysd deploy/
      @ssh_commands.last.should_not =~ /--migrate/
    end
  end

  context "choosing something to deploy" do
    before(:all) do
      api_scenario "one app, one environment"
      api_git_remote("user@git.host/path/to/repo.git")
    end

    after(:all) do
      api_git_remote(nil)
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
        ey "deploy giblets current-branch", :hide_err => true, :expect_failure => true
        @err.should =~ /deploy branch is set to "master"/
      end

      it "deploys a non-default branch with --force" do
        ey "deploy giblets current-branch --force"
        @ssh_commands.last.should =~ /--branch current-branch/
      end
    end
  end

  context "eysd install" do
    before(:all) do
      api_scenario "one app, one environment"
    end

    after(:all) do
      ENV['NO_SSH'] = "true"
    end

    it "installs eysd if 'eysd check' fails" do
      ENV.delete('NO_SSH')
      fake_ssh_no_eysd = "#!/usr/bin/env ruby\n exit!(127) if ARGV.last =~ /eysd check/"

      ey "deploy", :prepend_to_path => {'ssh' => fake_ssh_no_eysd}

      gem_install_command = @ssh_commands.find do |command|
        command =~ /gem install ey-deploy/
      end
      gem_install_command.should =~ %r{/usr/local/ey_resin/ruby/bin/gem install}
    end
  end
end
