require 'spec_helper'

print_my_args_ssh = "#!/bin/sh\necho ssh $*"

shared_examples_for "running ey ssh" do
  given "integration"
  include Spec::Helpers::SharedIntegrationTestUtils

  def extra_ey_options
    ssh_cmd = <<-RUBY
#!#{`which ruby`}
require "rubygems"
require "escape"
puts "ssh \#{Escape.shell_command(ARGV)}"
    RUBY
    {:prepend_to_path => {'ssh' => ssh_cmd}}
  end
end

shared_examples_for "running ey ssh for select role" do
  given "integration"
  include Spec::Helpers::SharedIntegrationTestUtils

  def extra_ey_options
    {:prepend_to_path => {'ssh' => "#!/bin/sh\necho ssh $*"}}
  end

  def command_to_run(opts)
    cmd = ["ssh", opts[:ssh_command]].compact + (@ssh_flag || [])
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd
  end

  it "runs the command on the right servers" do
    api_scenario "one app, one environment"
    run_ey(:ssh_command => "ls", :environment => 'giblets', :verbose => true)
    @hosts.each do |host|
      @raw_ssh_commands.select do |command|
        command =~ /^ssh turkey@#{host}.+ ls$/
      end.should_not be_empty
    end
    @raw_ssh_commands.select do |command|
      command =~ /^ssh turkey.+ ls$/
    end.count.should == @hosts.count
  end

  it "raises an error when there are no matching hosts" do
    api_scenario "one app, one environment, no instances"
    run_ey({:ssh_command => "ls", :environment => 'giblets', :verbose => true}, :expect_failure => true)
  end

  it "responds correctly when there is no command" do
    if @hosts.count != 1
      api_scenario "one app, one environment"
      run_ey({:environment => 'giblets', :verbose => true}, :expect_failure => true)
    end
  end
end

describe "ey ssh" do
  it_should_behave_like "running ey ssh"

  before(:all) do
    api_scenario "one app, many environments"
  end

  it "complains if it has no app master" do
    ey %w[ssh -e bakon], :expect_failure => true
    @err.should =~ /'bakon' does not have any matching instances/
  end

end

describe "ey ssh with an ambiguous git repo" do
  it_should_behave_like "running ey ssh"
  def command_to_run(_) %w[ssh ls] end
  it_should_behave_like "it requires an unambiguous git repo"
end

describe "ey ssh without a command" do
  it_should_behave_like "running ey ssh"

  def command_to_run(opts)
    cmd = ["ssh"]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    ssh_target = scenario[:ssh_username] + '@' + scenario[:master_hostname]
    @raw_ssh_commands.should == ["ssh #{ssh_target}"]
  end

  it_should_behave_like "it takes an environment name and an account name"
end

describe "ey ssh with a command" do
  it_should_behave_like "running ey ssh"

  def command_to_run(opts)
    cmd = %w[ssh ls]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    ssh_target = scenario[:ssh_username] + '@' + scenario[:master_hostname]
    @raw_ssh_commands.should == ["ssh #{ssh_target} ls"]
  end

  it_should_behave_like "it takes an environment name and an account name"
end

describe "ey ssh with a multi-part command" do
  it_should_behave_like "running ey ssh"

  def command_to_run(opts)
    cmd = ['ssh', 'echo "echo"']
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    ssh_target = scenario[:ssh_username] + '@' + scenario[:master_hostname]
    @raw_ssh_commands.should == ["ssh #{ssh_target} 'echo \"echo\"'"]
  end

  it_should_behave_like "it takes an environment name and an account name"
end

describe "ey ssh --all" do
  before do
    @ssh_flag = %w[--all]
    @hosts = %w(app_hostname 
                app_master_hostname 
                util_fluffy_hostname 
                util_rocky_hostname 
                db_master_hostname 
                db_slave_1_hostname 
                db_slave_2_hostname)
  end

  it_should_behave_like "running ey ssh"
  it_should_behave_like "running ey ssh for select role"
end

describe "ey ssh --app-servers" do
  before do
    @ssh_flag = %w[--app-servers]
    @hosts = %w(app_hostname app_master_hostname)
  end

  it_should_behave_like "running ey ssh"
  it_should_behave_like "running ey ssh for select role"
end

describe "ey ssh --db-master" do
  before do
    @ssh_flag = %w[--db-master]
    @hosts = %w(db_master_hostname)
  end

  it_should_behave_like "running ey ssh"
  it_should_behave_like "running ey ssh for select role"
end

describe "ey ssh --db-slaves" do
  before do
    @ssh_flag = %w[--db-slaves]
    @hosts = %w(db_slave_1_hostname db_slave_2_hostname)
  end

  it_should_behave_like "running ey ssh"
  it_should_behave_like "running ey ssh for select role"
end

describe "ey ssh --db-servers" do
  before do
    @ssh_flag = %w[--db-servers]
    @hosts = %w(db_master_hostname db_slave_1_hostname db_slave_2_hostname)
  end

  it_should_behave_like "running ey ssh"
  it_should_behave_like "running ey ssh for select role"
end

describe "ey ssh --utilities" do
  before do
    @ssh_flag = %w[--utilities]
    @hosts = %w(util_fluffy_hostname util_rocky_hostname)
  end

  it_should_behave_like "running ey ssh"
  it_should_behave_like "running ey ssh for select role"
end

describe "ey ssh --utilities fluffy" do
  before do
    @ssh_flag = %w[--utilities fluffy]
    @hosts = %w(util_fluffy_hostname)
  end

  it_should_behave_like "running ey ssh"
  it_should_behave_like "running ey ssh for select role"
end

describe "ey ssh --utilities fluffy rocky" do
  before do
    @ssh_flag = %w[--utilities fluffy rocky]
    @hosts = %w(util_fluffy_hostname util_rocky_hostname)
  end

  it_should_behave_like "running ey ssh"
  it_should_behave_like "running ey ssh for select role"
end

