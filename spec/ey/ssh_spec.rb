require 'spec_helper'

print_my_args_ssh = "#!/bin/sh\necho ssh $*"

shared_examples_for "running ey ssh" do
  given "integration"
  include Spec::Helpers::SharedIntegrationTestUtils

  def extra_ey_options
    {:prepend_to_path => {'ssh' => "#!/bin/sh\necho ssh $*"}}
  end
end

describe "ey ssh" do
  it_should_behave_like "running ey ssh"

  before(:all) do
    api_scenario "one app, many environments"
  end

  it "complains if it has no app master" do
    ey "ssh -e bakon", :expect_failure => true
    @err.should =~ /'bakon' does not have a master instance/
  end

end

describe "ey ssh without a command" do
  it_should_behave_like "running ey ssh"

  def command_to_run(opts)
    cmd = "ssh"
    cmd << " --environment #{opts[:env]}" if opts[:env]
    cmd
  end

  def verify_ran(scenario)
    ssh_target = scenario[:ssh_username] + '@' + scenario[:master_hostname]
    @raw_ssh_commands.should == ["ssh #{ssh_target}"]
  end

  it_should_behave_like "it takes an environment name"
end

describe "ey ssh with a command" do
  it_should_behave_like "running ey ssh"

  def command_to_run(opts)
    cmd = "ssh ls"
    cmd << " --environment #{opts[:env]}" if opts[:env]
    cmd
  end

  def verify_ran(scenario)
    ssh_target = scenario[:ssh_username] + '@' + scenario[:master_hostname]
    @raw_ssh_commands.should == ["ssh #{ssh_target} ls"]
  end

  it_should_behave_like "it takes an environment name"
end


describe "ey ssh --all with a command" do
  it_should_behave_like "running ey ssh"

  def command_to_run(opts)
    cmd = "ssh ls"
    cmd << " --all"
    cmd << " --environment #{opts[:env]}" if opts[:env]
    cmd
  end

  it "runs the command on all servers" do
    api_scenario "one app, one environment"
    run_ey(:env => 'giblets', :verbose => true)
    @raw_ssh_commands.count do |command|
      command =~ /^ssh turkey@.+ ls$/
    end.should == 4
  end
end

describe "ey ssh --all without a command" do
  it_should_behave_like "running ey ssh"

  def command_to_run(opts)
    cmd = "ssh"
    cmd << " --all"
    cmd << " --environment #{opts[:env]}" if opts[:env]
    cmd
  end

  it "raises an error" do
    api_scenario "one app, one environment"
    run_ey({:env => 'giblets', :verbose => true}, :expect_failure => true)
    @err.grep(/NoCommandError/)
  end
end

describe "ey ssh --all without servers" do
  it_should_behave_like "running ey ssh"

  def command_to_run(opts)
    cmd = "ssh ls"
    cmd << " --all"
    cmd << " --environment #{opts[:env]}" if opts[:env]
    cmd
  end

  it "raises an error" do
    api_scenario "one app, one environment, no instances"
    run_ey({:env => 'giblets', :verbose => true}, :expect_failure => true)
    @err.grep(/NoInstancesError/)
  end
end
