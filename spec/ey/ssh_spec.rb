require 'spec_helper'

print_my_args_ssh = "#!/bin/sh\necho ssh $*"

shared_examples_for "running ey ssh" do
  given "integration"

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

  def extra_ey_options
    {:prepend_to_path => {'ssh' => "#!/bin/sh\necho ssh $*"}}
  end

  def command_to_run(opts)
    cmd = ["ssh", opts[:ssh_command]].compact + (@ssh_flag || [])
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--shell"       << opts[:shell]       if opts[:shell]
    cmd << "--no-shell"                          if opts[:no_shell]
    cmd << "--quiet"                             if opts[:quiet]
    cmd
  end

  it "runs the command on the right servers" do
    login_scenario "one app, one environment"
    ey command_to_run(:ssh_command => "ls", :environment => 'giblets', :verbose => true)
    @hosts.each do |host|
      @raw_ssh_commands.select do |command|
        command =~ /^ssh turkey@#{host}.+ ls$/
      end.should_not be_empty
    end
    @raw_ssh_commands.select do |command|
      command =~ /^ssh turkey.+ ls$/
    end.count.should == @hosts.count
  end

  it "is quiet" do
    login_scenario "one app, one environment"
    ey command_to_run(:ssh_command => "ls", :environment => 'giblets', :quiet => true)
    @out.should =~ /ssh.*ls/
    @out.should_not =~ /Loading application data/
  end

  it "runs in bash by default" do
    login_scenario "one app, one environment"
    ey command_to_run(:ssh_command => "ls", :environment => 'giblets')
    @out.should =~ /ssh.*bash -lc ls/
  end

  it "excludes shell with --no-shell" do
    login_scenario "one app, one environment"
    ey command_to_run(:ssh_command => "ls", :environment => 'giblets', :no_shell => true)
    @out.should_not =~ /bash/
    @out.should =~ /ssh.*ls/
  end

  it "accepts an alternate shell" do
    login_scenario "one app, one environment"
    ey command_to_run(:ssh_command => "ls", :environment => 'giblets', :shell => 'zsh')
    @out.should =~ /ssh.*zsh -lc ls/
  end

  it "raises an error when there are no matching hosts" do
    login_scenario "one app, one environment, no instances"
    ey command_to_run({:ssh_command => "ls", :environment => 'giblets', :verbose => true}), :expect_failure => true
  end

  it "responds correctly when there is no command" do
    if @hosts.count != 1
      login_scenario "one app, one environment"
      ey command_to_run({:environment => 'giblets', :verbose => true}), :expect_failure => true
    end
  end
end

describe "ey ssh" do
  include_examples "running ey ssh"

  before(:all) do
    login_scenario "one app, many environments"
  end

  it "complains if it has no app master" do
    ey %w[ssh -e bakon], :expect_failure => true
    @err.should =~ /'bakon' does not have any matching instances/
  end

end

describe "ey ssh with an ambiguous git repo" do
  include_examples "running ey ssh"
  def command_to_run(_) %w[ssh ls] end
  include_examples "it requires an unambiguous git repo"
end

describe "ey ssh without a command" do
  include_examples "running ey ssh"

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

  include_examples "it takes an environment name and an account name"
end

describe "ey ssh with a command" do
  include_examples "running ey ssh"

  def command_to_run(opts)
    cmd = %w[ssh ls]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd << "--shell"       << opts[:shell]       if opts[:shell]
    cmd << "--no-shell"                          if opts[:no_shell]
    cmd
  end

  def verify_ran(scenario)
    ssh_target = scenario[:ssh_username] + '@' + scenario[:master_hostname]
    @raw_ssh_commands.should == ["ssh #{ssh_target} 'bash -lc ls'"]
  end

  include_examples "it takes an environment name and an account name"
end

describe "ey ssh with a command that fails" do
  given "integration"

  def extra_ey_options
    ssh_cmd = "false" # fail immediately
    {:prepend_to_path => {'ssh' => ssh_cmd}}
  end

  def command_to_run(opts)
    cmd = %w[ssh ls]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd << "--shell"       << opts[:shell]       if opts[:shell]
    cmd << "--no-shell"                          if opts[:no_shell]
    cmd
  end

  it "fails just like the ssh command fails" do
    login_scenario "one app, one environment"
    ey command_to_run({:ssh_command => "ls", :environment => 'giblets', :verbose => true}), :expect_failure => true
  end
end

describe "ey ssh with a multi-part command" do
  include_examples "running ey ssh"

  def command_to_run(opts)
    cmd = ['ssh', 'echo "echo"']
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd << "--shell"       << opts[:shell]       if opts[:shell]
    cmd << "--no-shell"                          if opts[:no_shell]
    cmd
  end

  def verify_ran(scenario)
    ssh_target = scenario[:ssh_username] + '@' + scenario[:master_hostname]
    @raw_ssh_commands.should == ["ssh #{ssh_target} 'bash -lc '\\''echo \"echo\"'\\'"]
  end

  include_examples "it takes an environment name and an account name"
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

  include_examples "running ey ssh"
  include_examples "running ey ssh for select role"
end

describe "ey ssh --app-servers" do
  before do
    @ssh_flag = %w[--app-servers]
    @hosts = %w(app_hostname app_master_hostname)
  end

  include_examples "running ey ssh"
  include_examples "running ey ssh for select role"
end

describe "ey ssh --db-master" do
  before do
    @ssh_flag = %w[--db-master]
    @hosts = %w(db_master_hostname)
  end

  include_examples "running ey ssh"
  include_examples "running ey ssh for select role"
end

describe "ey ssh --db-slaves" do
  before do
    @ssh_flag = %w[--db-slaves]
    @hosts = %w(db_slave_1_hostname db_slave_2_hostname)
  end

  include_examples "running ey ssh"
  include_examples "running ey ssh for select role"
end

describe "ey ssh --db-servers" do
  before do
    @ssh_flag = %w[--db-servers]
    @hosts = %w(db_master_hostname db_slave_1_hostname db_slave_2_hostname)
  end

  include_examples "running ey ssh"
  include_examples "running ey ssh for select role"
end

describe "ey ssh --utilities" do
  before do
    @ssh_flag = %w[--utilities]
    @hosts = %w(util_fluffy_hostname util_rocky_hostname)
  end

  include_examples "running ey ssh"
  include_examples "running ey ssh for select role"
end

describe "ey ssh --utilities fluffy" do
  before do
    @ssh_flag = %w[--utilities fluffy]
    @hosts = %w(util_fluffy_hostname)
  end

  include_examples "running ey ssh"
  include_examples "running ey ssh for select role"
end

describe "ey ssh --utilities fluffy rocky" do
  before do
    @ssh_flag = %w[--utilities fluffy rocky]
    @hosts = %w(util_fluffy_hostname util_rocky_hostname)
  end

  include_examples "running ey ssh"
  include_examples "running ey ssh for select role"
end

