require 'ostruct'

shared_examples_for "it has an ambiguous git repo" do

  define_git_repo('dup test') do
    system("git remote add dup git://github.com/engineyard/dup.git")
  end

  use_git_repo('dup test')

  before(:all) do
    login_scenario "two apps, same git uri"
  end
end

shared_examples_for "it requires an unambiguous git repo" do
  include_examples "it has an ambiguous git repo"

  it "lists disambiguating environments to choose from" do
    run_ey({}, {:expect_failure => true})
    @err.should =~ /ambiguous/
    @err.should =~ /specify one of the following environments/
    @err.should =~ /giblets \(main\)/
    @err.should =~ /keycollector_production \(main\)/
  end
end

shared_examples_for "it takes an environment name and an app name and an account name" do
  include_examples "it takes an app name"
  include_examples "it takes an environment name"

  context "when multiple accounts with collaboration" do
    before :all do
      login_scenario "two accounts, two apps, two environments, ambiguous"
    end

    it "fails when the app and environment are ambiguous across accounts" do
      run_ey({:environment => "giblets", :app => "rails232app", :ref => 'master'}, {:expect_failure => true})
      @err.should match(/Multiple application environments possible/i)
      @err.should match(/ey \S+ --account='account_2' --app='rails232app' --environment='giblets'/i)
      @err.should match(/ey \S+ --account='main' --app='rails232app' --environment='giblets'/i)
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
  include_examples "it takes an environment name"

  context "when multiple accounts with collaboration" do
    before :all do
      login_scenario "two accounts, two apps, two environments, ambiguous"
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

    context "when the backend raises an error" do
      before do
        failed_response = RestClient::Response.create(
          '{ "message": "Important infos about how you failed!"}', OpenStruct.new(:code => 400), nil)
        RestClient.stub!(:send).and_raise(RestClient::RequestFailed.new(failed_response))
      end

      it "returns the error message to the user" do
        fast_failing_ey(command_to_run({:environment => "giblets", :account => "main"}))
        @err.should match(/400.*Important infos/)
      end
    end

  end
end

shared_examples_for "it takes an environment name" do
  it "operates on the current environment by default" do
    login_scenario "one app, one environment"
    run_ey(:environment => nil)
    verify_ran(make_scenario({
          :environment      => 'giblets',
          :application      => 'rails232app',
          :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
          :ssh_username     => 'turkey',
        }))
  end

  it "complains when you specify a nonexistent environment" do
    login_scenario "one app, one environment"
    # This test must shell out (not sure why, plz FIXME)
    ey command_to_run(:environment => 'typo-happens-here'), {:expect_failure => true}
    @err.should match(/No environment found matching .*typo-happens-here/i)
  end

  context "outside a git repo" do

    define_git_repo("not actually a git repo") do |git_dir|
      # in case we screw up and are not in a freshly-generated test
      # git repository, don't blow away the thing we're developing
      system("rm -rf .git") if `git remote -v`.include?("path/to/repo.git")
      git_dir.join("cookbooks").mkdir
      link_recipes_tgz(git_dir)
    end

    use_git_repo("not actually a git repo")

    before :all do
      login_scenario "one app, one environment"
    end

    it "works (and does not complain about git remotes)" do
      run_ey({:environment => 'giblets'}) unless @takes_app_name
    end

  end

  context "given a piece of the environment name" do
    before(:all) do
      login_scenario "one app, many similarly-named environments"
    end

    it "complains when the substring is ambiguous" do
      run_ey({:environment => 'staging'}, {:expect_failure => true})
      if @takes_app_name
        @err.should match(/multiple application environments possible/i)
      else
        @err.should match(/multiple environments possible/i)
      end
    end

    it "works when the substring is unambiguous" do
      login_scenario "one app, many similarly-named environments"
      run_ey({:environment => 'prod', :migrate => true}, {:debug => true})
      verify_ran(make_scenario({
        :environment      => 'railsapp_production',
        :application      => 'rails232app',
        :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
        :ssh_username     => 'turkey',
      }))
    end
  end

  it "complains when it can't guess the environment and its name isn't specified" do
    login_scenario "one app, one environment, not linked"
    run_ey({:environment => nil}, {:expect_failure => true})
    @err.should match(/No environment found for applications matching remotes:/i)
  end
end

shared_examples_for "it takes an app name" do
  before { @takes_app_name = true }

  it "allows you to specify a valid app" do
    login_scenario "one app, one environment"
    Dir.chdir(Dir.tmpdir) do
      run_ey({:environment => 'giblets', :app => 'rails232app', :ref => 'master', :migrate => nil}, {})
      verify_ran(make_scenario({
            :environment      => 'giblets',
            :application      => 'rails232app',
            :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
            :ssh_username     => 'turkey',
          }))
    end
  end

  it "can guess the environment from the app" do
    login_scenario "two apps"
    Dir.chdir(Dir.tmpdir) do
      run_ey({:app => 'rails232app', :ref => 'master', :migrate => true}, {})
      verify_ran(make_scenario({
            :environment      => 'giblets',
            :application      => 'rails232app',
            :master_hostname  => 'app_master_hostname.compute-1.amazonaws.com',
            :ssh_username     => 'turkey',
          }))
    end
  end

  it "complains when you specify a nonexistant app" do
    login_scenario "one app, one environment"
    run_ey({:environment => 'giblets', :app => 'P-time-SAT-solver', :ref => 'master'},
      {:expect_failure => true})
    @err.should =~ /No app.*P-time-SAT-solver/i
  end

end

shared_examples_for "it invokes engineyard-serverside" do
  context "with arguments" do
    before(:all) do
      login_scenario "one app, one environment"
      run_ey({:environment => 'giblets', :verbose => true})
    end

    it "passes --verbose to engineyard-serverside" do
      @ssh_commands.should have_command_like(/engineyard-serverside.*deploy.*--verbose/)
    end

    it "passes along instance information to engineyard-serverside" do
      instance_args = [
        /--instances app_hostname[^\s]+ localhost util_fluffy/,
        /--instance-roles app_hostname[^\s]+:app localhost:app_master util_fluffy[^\s]+:util/,
        /--instance-names util_fluffy_hostname[^\s]+:fluffy/
      ]

      db_instance = /db_master/

      # apps + utilities are all mentioned
      instance_args.each do |i|
        @ssh_commands.last.should =~ /#{i}/
      end

      # but not database instances
      @ssh_commands.last.should_not =~ /#{db_instance}/
    end

  end

  context "when no instances have names" do
    before(:each) do
      login_scenario "two apps"
      run_ey({:env => 'giblets', :app => 'rails232app', :ref => 'master', :migrate => true, :verbose => true})
    end

    it "omits the --instance-names parameter" do
      @ssh_commands.last.should_not include("--instance-names")
    end
  end
end
