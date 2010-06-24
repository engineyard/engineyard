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


shared_examples_for "it takes an environment name" do
  include Spec::Helpers::SharedIntegrationTestUtils

  it "operates on the current environment by default" do
    api_scenario "one app, one environment"
    run_ey({:env => nil}, {:debug => true})
    verify_ran(make_scenario({
          :environment      => 'giblets',
          :application      => 'rails232app',
          :master_hostname  => 'ec2-174-129-198-124.compute-1.amazonaws.com',
          :ssh_username     => 'turkey',
        }))
  end

  it "complains when you specify a nonexistent environment" do
    api_scenario "one app, one environment"
    run_ey({:env => 'typo-happens-here'}, {:expect_failure => true})
    @err.should match(/no environment named 'typo-happens-here'/i)
  end

  context "given a piece of the environment name" do
    before(:all) do
      api_scenario "one app, many similarly-named environments"
    end

    it "complains when the substring is ambiguous" do
      run_ey({:env => 'staging'}, {:expect_failure => true})
      @err.should match(/'staging' is ambiguous/)
    end

    it "works when the substring is unambiguous" do
      api_scenario "one app, many similarly-named environments"
      run_ey({:env => 'prod'}, {:debug => true})
      verify_ran(make_scenario({
            :environment      => 'railsapp_production',
            :application      => 'rails232app',
            :master_hostname  => 'ec2-174-129-198-124.compute-1.amazonaws.com',
            :ssh_username     => 'turkey',
          }))
    end
  end

  it "complains when it can't guess the environment and its name isn't specified" do
    api_scenario "one app, one environment, not linked"
    run_ey({:env => nil}, {:expect_failure => true})
    @err.should =~ /single environment/i
  end
end

shared_examples_for "it takes an app name" do
  include Spec::Helpers::SharedIntegrationTestUtils

  it "allows you to specify a valid app" do
    api_scenario "one app, one environment"
    Dir.chdir(Dir.tmpdir) do
      run_ey({:env => 'giblets', :app => 'rails232app', :ref => 'master'}, {})
      verify_ran(make_scenario({
            :environment      => 'giblets',
            :application      => 'rails232app',
            :master_hostname  => 'ec2-174-129-198-124.compute-1.amazonaws.com',
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
            :master_hostname  => 'ec2-174-129-198-124.compute-1.amazonaws.com',
            :ssh_username     => 'turkey',
          }))
    end
  end

  it "complains when you specify a nonexistant app" do
    api_scenario "one app, one environment"
    run_ey({:env => 'giblets', :app => 'P-time-SAT-solver', :ref => 'master'},
      {:expect_failure => true})
    @err.should =~ /no app.*P-time-SAT-solver/i
  end

end

shared_examples_for "it invokes eysd" do
  include Spec::Helpers::SharedIntegrationTestUtils

  it "passes along instance information to eysd" do
    api_scenario "one app, one environment"
    run_ey({:env => 'giblets'})

    instance_args = [
      Regexp.quote("ec2-174-129-198-124.compute-1.amazonaws.com,app_master"),
      Regexp.quote("ec2-174-129-142-53.compute-1.amazonaws.com,db_master"),
      Regexp.quote("ec2-72-44-46-66.compute-1.amazonaws.com,app"),
      Regexp.quote("ec2-184-73-116-228.compute-1.amazonaws.com,util,fluffy"),
    ]

    # they should all be mentioned
    instance_args.each do |i|
      @ssh_commands.last.should =~ /#{i}/
    end

    # after the option '--instances'
    @ssh_commands.last.should match(/--instances (#{instance_args.join('|')})/)
  end

  context "eysd installation" do
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
      "#!/usr/bin/env ruby\n exit!(#{exit_code}) if ARGV.to_s =~ /gem list ey-deploy/"
    end

    it "raises an error if SSH fails" do
      run_ey({:env => 'giblets'},
        {:prepend_to_path => {'ssh' => exiting_ssh(255)}, :expect_failure => true})
      @err.should =~ /SSH connection to \S+ failed/
    end

    it "installs ey-deploy if it's missing" do
      run_ey({:env => 'giblets'}, {:prepend_to_path => {'ssh' => exiting_ssh(1)}})

      gem_install_command = @ssh_commands.find do |command|
        command =~ /gem install ey-deploy/
      end
      gem_install_command.should_not be_nil
      gem_install_command.should =~ %r{/usr/local/ey_resin/ruby/bin/gem install.*ey-deploy}
    end

    it "does not try to install ey-deploy if it's already there" do
      run_ey({:env => 'giblets'}, {:prepend_to_path => {'ssh' => exiting_ssh(0)}})
      @ssh_commands.should_not have_command_like(/gem install ey-deploy/)
      ver = Regexp.quote(EY::Model::Instance::EYSD_VERSION)
      @ssh_commands.should have_command_like(/eysd _#{ver}_ deploy/)
    end
  end
end
