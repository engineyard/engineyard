require 'spec_helper'

print_my_args_ssh = "#!/bin/sh\necho ssh $*"

shared_examples_for "running ey console" do
  given "integration"

  def extra_ey_options
    {:prepend_to_path => {'ssh' => "#!/bin/sh\necho ssh $*"}}
  end

  def command_to_run(opts)
    cmd = ["console"]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--quiet"                             if opts[:quiet]
    cmd
  end
end

describe "ey console" do
  include_examples "running ey console"

  it "complains if it has no app master" do
    login_scenario "one app, many environments"
    ey %w[console -e bakon], :expect_failure => true
    expect(@err).to match(/'bakon' does not have any matching instances/)
  end

  it "opens the console on the right server" do
    login_scenario "one app, one environment"
    ey command_to_run(:environment => 'giblets', :verbose => true)
    expect(@raw_ssh_commands.select do |command|
      command =~ /^ssh -t turkey@app_master_hostname.+ bash -lc '.+bundle exec rails console'$/
    end).not_to be_empty
    expect(@raw_ssh_commands.select do |command|
      command =~ /^ssh -t turkey.+$/
    end.count).to eq(1)
  end

  it "is quiet" do
    login_scenario "one app, one environment"
    ey command_to_run(:environment => 'giblets', :quiet => true)
    expect(@out).to match(/ssh.*-t turkey/)
    expect(@out).not_to match(/Loading application data/)
  end

  it "runs in bash by default" do
    login_scenario "one app, one environment"
    ey command_to_run(:environment => 'giblets', :quiet => true)
    expect(@out).to match(/ssh.*bash -lc '.+bundle/)
  end

  it "raises an error when there are no matching hosts" do
    login_scenario "one app, one environment, no instances"
    ey command_to_run(:environment => 'giblets', :quiet => true), :expect_failure => true
  end
end
