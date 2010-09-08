module Spec
  module Helpers
    module SharedIntegrationTestUtils

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
  end
end

shared_examples_for "it has an ambiguous git repo" do
  include Spec::Helpers::SharedIntegrationTestUtils

  define_git_repo('dup test') do
    system("git remote add dup git://github.com/engineyard/dup.git")
  end

  use_git_repo('dup test')

  before(:all) do
    api_scenario "two apps, same git uri"
  end
end

shared_examples_for "it requires an unambiguous git repo" do
  it_should_behave_like "it has an ambiguous git repo"

  it "lists disambiguating environments to choose from" do
    run_ey({}, {:expect_failure => true})
    @err.should =~ /ambiguous/
    @err.should =~ /specify one of the following environments/
    @err.should =~ /giblets \(main\)/
    @err.should =~ /keycollector_production \(main\)/
  end
end

shared_examples_for "it takes an environment name and an app name and an account name" do
  it_should_behave_like "it takes an app name"
  it_should_behave_like "it takes an environment name"

  context "when multiple accounts with collaboration" do
    before :all do
      api_scenario "two accounts, two apps, two environments, ambiguous"
    end

    it "fails when the app and environment are ambiguous across accounts" do
      run_ey({:environment => "giblets", :app => "rails232app", :ref => 'master'}, {:expect_failure => true})
      @err.should match(/Multiple app deployments possible/i)
      @err.should match(/ey \S+ --environment='giblets' --app='rails232app' --account='account_2'/i)
      @err.should match(/ey \S+ --environment='giblets' --app='rails232app' --account='main'/i)
    end

    it "runs when specifying the account disambiguates the app to deploy" do
      run_ey({:environment => "giblets", :app => "rails232app", :account => "main", :ref => 'master'})
      verify_ran(make_scenario({
          :environment      => 'giblets',
          :application      => 'rails232app',
          :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
          :ssh_username     => 'turkey',
        }))
    end
  end
end

shared_examples_for "it takes an environment name and an account name" do
  it_should_behave_like "it takes an environment name"

  context "when multiple accounts with collaboration" do
    before :all do
      api_scenario "two accounts, two apps, two environments, ambiguous"
    end

    it "fails when the app and environment are ambiguous across accounts" do
      run_ey({:environment => "giblets"}, {:expect_failure => true})
      @err.should match(/multiple environments possible/i)
      @err.should match(/ey \S+ --environment='giblets' --account='account_2'/i)
      @err.should match(/ey \S+ --environment='giblets' --account='main'/i)
    end

    it "runs when specifying the account disambiguates the app to deploy" do
      run_ey({:environment => "giblets", :account => "main"})
      verify_ran(make_scenario({
          :environment      => 'giblets',
          :application      => 'rails232app',
          :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
          :ssh_username     => 'turkey',
        }))
    end
  end
end

shared_examples_for "it takes an environment name" do
  include Spec::Helpers::SharedIntegrationTestUtils

  it "operates on the current environment by default" do
    api_scenario "one app, one environment"
    run_ey({:environment => nil}, {:debug => true})
    verify_ran(make_scenario({
          :environment      => 'giblets',
          :application      => 'rails232app',
          :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
          :ssh_username     => 'turkey',
        }))
  end

  it "complains when you specify a nonexistent environment" do
    api_scenario "one app, one environment"
    run_ey({:environment => 'typo-happens-here'}, {:expect_failure => true})
    @err.should match(/no environment named 'typo-happens-here'/i)
  end

  context "outside a git repo" do
    define_git_repo("not actually a git repo") do |git_dir|
      # in case we screw up and are not in a freshly-generated test
      # git repository, don't blow away the thing we're developing
      system("rm -rf .git") if `git remote -v`.include?("path/to/repo.git")
      git_dir.join("cookbooks").mkdir
    end

    use_git_repo("not actually a git repo")

    before :all do
      api_scenario "one app, one environment"
    end

    it "works (and does not complain about git remotes)" do
      run_ey({:environment => 'giblets'}) unless @takes_app_name
    end

  end

  context "given a piece of the environment name" do
    before(:all) do
      api_scenario "one app, many similarly-named environments"
    end

    it "complains when the substring is ambiguous" do
      run_ey({:environment => 'staging'}, {:expect_failure => true})
      if @takes_app_name
        @err.should match(/multiple app deployments possible/i)
      else
        @err.should match(/multiple environments possible/i)
      end
    end

    it "works when the substring is unambiguous" do
      api_scenario "one app, many similarly-named environments"
      run_ey({:environment => 'prod'}, {:debug => true})
      verify_ran(make_scenario({
            :environment      => 'railsapp_production',
            :application      => 'rails232app',
            :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
            :ssh_username     => 'turkey',
          }))
    end
  end

  it "complains when it can't guess the environment and its name isn't specified" do
    api_scenario "one app, one environment, not linked"
    run_ey({:environment => nil}, {:expect_failure => true})
    @err.should match(/there is no application configured/i)
  end
end

shared_examples_for "it takes an app name" do
  include Spec::Helpers::SharedIntegrationTestUtils
  before { @takes_app_name = true }

  it "allows you to specify a valid app" do
    api_scenario "one app, one environment"
    Dir.chdir(Dir.tmpdir) do
      run_ey({:environment => 'giblets', :app => 'rails232app', :ref => 'master'}, {})
      verify_ran(make_scenario({
            :environment      => 'giblets',
            :application      => 'rails232app',
            :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
            :ssh_username     => 'turkey',
          }))
    end
  end

  it "can guess the environment from the app" do
    api_scenario "two apps"
    Dir.chdir(Dir.tmpdir) do
      run_ey({:app => 'rails232app', :ref => 'master'}, {})
      verify_ran(make_scenario({
            :environment      => 'giblets',
            :application      => 'rails232app',
            :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
            :ssh_username     => 'turkey',
          }))
    end
  end

  it "complains when you specify a nonexistant app" do
    api_scenario "one app, one environment"
    run_ey({:environment => 'giblets', :app => 'P-time-SAT-solver', :ref => 'master'},
      {:expect_failure => true})
    @err.should =~ /no app.*P-time-SAT-solver/i
  end

end

shared_examples_for "it invokes engineyard-serverside" do
  include Spec::Helpers::SharedIntegrationTestUtils

  context "with arguments" do
    before(:all) do
      api_scenario "one app, one environment"
      run_ey({:environment => 'giblets', :verbose => true})
    end

    it "passes --verbose to engineyard-serverside" do
      @ssh_commands.should have_command_like(/engineyard-serverside.*deploy.*--verbose/)
    end

    it "passes along instance information to engineyard-serverside" do
      instance_args = [
        Regexp.quote("app_master_hostname.compute-1.amazonaws.com,app_master"),
        Regexp.quote("app_hostname.compute-1.amazonaws.com,app"),
        Regexp.quote("util_fluffy_hostname.compute-1.amazonaws.com,util,fluffy"),
      ]

      db_instance = Regexp.quote("db_master_hostname.compute-1.amazonaws.com,db_master")

      # apps + utilities are all mentioned
      instance_args.each do |i|
        @ssh_commands.last.should =~ /#{i}/
      end

      # but not database instances
      @ssh_commands.last.should_not =~ /#{db_instance}/

      # and it's all after the option '--instances'
      @ssh_commands.last.should match(/--instances (#{instance_args.join('|')})/)
    end

    it "passes the framework environment" do
      @ssh_commands.last.should match(/--framework-env production/)
    end

  end


  context "engineyard-serverside installation" do
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
      "#!/usr/bin/env ruby\n exit!(#{exit_code}) if ARGV.to_s =~ /gem list engineyard-serverside/"
    end

    it "raises an error if SSH fails" do
      run_ey({:environment => 'giblets'},
        {:prepend_to_path => {'ssh' => exiting_ssh(255)}, :expect_failure => true})
      @err.should =~ /SSH connection to \S+ failed/
    end

    it "installs engineyard-serverside if it's missing" do
      run_ey({:environment => 'giblets'}, {:prepend_to_path => {'ssh' => exiting_ssh(1)}})

      gem_install_command = @ssh_commands.find do |command|
        command =~ /gem install engineyard-serverside/
      end
      gem_install_command.should_not be_nil
      gem_install_command.should =~ %r{/usr/local/ey_resin/ruby/bin/gem install.*engineyard-serverside}
    end

    it "does not try to install engineyard-serverside if it's already there" do
      run_ey({:environment => 'giblets'}, {:prepend_to_path => {'ssh' => exiting_ssh(0)}})
      @ssh_commands.should_not have_command_like(/gem install engineyard-serverside/)
      ver = Regexp.quote(EY::ENGINEYARD_SERVERSIDE_VERSION)
      @ssh_commands.should have_command_like(/engineyard-serverside _#{ver}_ deploy/)
    end
  end  
end

shared_examples_for "model collections" do
  describe "#match_one" do
    it "works when given an unambiguous substring" do
      @collection.match_one("prod").name.should == "app_production"
    end

    it "raises an error when given an ambiguous substring" do
      lambda {
        @collection.match_one("staging")
      }.should raise_error(@collection_class.ambiguous_error)
    end

    it "returns an exact match if one exists" do
      @collection.match_one("app_staging").name.should == "app_staging"
    end

    it "returns nil when it can't find anything" do
      @collection.match_one("dev-and-production").should be_nil
    end
 end

  describe "#match_one!" do
    it "works when given an unambiguous substring" do
      @collection.match_one!("prod").name.should == "app_production"
    end

    it "raises an error when given an ambiguous substring" do
      lambda {
        @collection.match_one!("staging")
      }.should raise_error(@collection_class.ambiguous_error)
    end

    it "returns an exact match if one exists" do
      @collection.match_one!("app_staging").name.should == "app_staging"
    end

    it "raises an error when given an ambiguous exact string" do
      lambda {
        @collection.match_one!("app_duplicate")
      }.should raise_error(@collection_class.ambiguous_error)
    end

    it "raises an error when it can't find anything" do
      lambda {
        @collection.match_one!("dev-and-production")
      }.should raise_error(@collection_class.invalid_error)
    end
  end

  describe "#named" do
    it "finds matching by name" do
      @collection.named("app_staging").name.should == "app_staging"
    end

    it "returns nil when no name matches" do
      @collection.named("something else").should be_nil
    end
  end
end
