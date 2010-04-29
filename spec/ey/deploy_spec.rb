require 'spec_helper'

describe "ey deploy" do
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
    end

    it "prompts for authentication" do
      ey("deploy", :hide_err => true) do |input|
        input.puts("test@test.test")
        input.puts("test")
      end

      @out.should include("We need to fetch your API token, please login")
      @out.should include("Email:")
      @out.should include("Password:")
    end
  end

  describe "with an eyrc file" do
    before(:each) do
      token = { ENV['CLOUD_URL'] => {
        "api_token" => "f81a1706ddaeb148cfb6235ddecfc1cf"} }
      File.open(ENV['EYRC'], "w"){|f| YAML.dump(token, f) }
    end

    it "complains when there is no app" do
      api_scenario "empty"
      ey "deploy", :hide_err => true
      @err.should include(%|no application configured|)
    end

    it "complains when there is no environment for the app" do
      api_scenario "one app, one environment, not linked"
      ey "deploy giblets master", :hide_err => true
      @err.should match(/doesn't run this application/i)
    end

    it "runs when environment is known" do
      api_scenario "one app, one environment"
      ey "deploy", :hide_err => true
      @out.should match(/running deploy/i)
      @err.should be_empty
    end

    it "complains when environment is ambiguous" do
      api_scenario "one app, two environments"
      ey "deploy", :hide_err => true
      @err.should match(/was called incorrectly/i)
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

end
