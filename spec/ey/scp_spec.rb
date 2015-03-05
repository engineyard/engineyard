require 'spec_helper'

shared_examples_for "running ey scp" do
  given "integration"

  def extra_ey_options
    {:prepend_to_path => {'scp' => "#!/bin/sh\necho scp $*"}}
  end
end

shared_examples_for "running ey scp for select role" do
  given "integration"

  def extra_ey_options
    {:prepend_to_path => {'scp' => "#!/bin/sh\necho scp $*"}}
  end

  def command_to_run(opts)
    cmd = ["scp", opts[:from], opts[:to]].compact + (@scp_flag || [])
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--quiet"                             if opts[:quiet]
    cmd
  end

  it "runs the command on the right servers" do
    login_scenario "one app, one environment"
    ey command_to_run(from: "from", to: "to", environment: 'giblets', verbose: true)
    @hosts.each do |host_prefix|
      expect(@raw_ssh_commands.grep(/^scp from turkey@#{host_prefix}.+:to$/)).not_to be_empty
    end
    expect(@raw_ssh_commands.grep(/^scp from turkey@.+:to$/).count).to eq(@hosts.count)
  end

  it "is quiet" do
    login_scenario "one app, one environment"
    ey command_to_run(from: "from", to: "to", environment: 'giblets', quiet: true)
    expect(@out).to match(/scp.*from.*to/)
    expect(@out).not_to match(/Loading application data/)
  end

  it "raises an error when there are no matching hosts" do
    login_scenario "one app, one environment, no instances"
    ey command_to_run({from: "from", to: "to", environment: 'giblets', verbose: true}), expect_failure: true
  end

  it "errors correctly when no file paths are specified" do
    login_scenario "one app, one environment"
    ey command_to_run({environment: 'giblets', verbose: true}), expect_failure: true
    ey command_to_run({from: "from", environment: 'giblets', verbose: true}), expect_failure: true
  end
end

describe "ey scp" do
  include_examples "running ey scp"

  before(:all) do
    login_scenario "one app, many environments"
  end

  it "complains if it has no app master" do
    ey %w[scp from to -e bakon], :expect_failure => true
    expect(@err).to match(/'bakon' does not have any matching instances/)
  end

end

describe "ey scp with an ambiguous git repo" do
  include_examples "running ey scp"
  def command_to_run(_) %w[scp from to] end
  include_examples "it requires an unambiguous git repo"
end

describe "ey scp" do
  include_examples "running ey scp"

  def command_to_run(opts)
    cmd = %w[scp HOST:from to]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    scp_target = scenario[:ssh_username] + '@' + scenario[:master_hostname]
    expect(@raw_ssh_commands).to eq(["scp #{scp_target}:from to"])
  end

  include_examples "it takes an environment name and an account name"
end

describe "ey scp --all" do
  before do
    @scp_flag = %w[--all]
    @hosts = %w(app_hostname
                app_master_hostname
                util_fluffy_hostname
                util_rocky_hostname
                db_master_hostname
                db_slave_1_hostname
                db_slave_2_hostname)
  end

  include_examples "running ey scp"
  include_examples "running ey scp for select role"
end

describe "ey scp --app-servers" do
  before do
    @scp_flag = %w[--app-servers]
    @hosts = %w(app_hostname app_master_hostname)
  end

  include_examples "running ey scp"
  include_examples "running ey scp for select role"
end

describe "ey scp --db-master" do
  before do
    @scp_flag = %w[--db-master]
    @hosts = %w(db_master_hostname)
  end

  include_examples "running ey scp"
  include_examples "running ey scp for select role"
end

describe "ey scp --db-slaves" do
  before do
    @scp_flag = %w[--db-slaves]
    @hosts = %w(db_slave_1_hostname db_slave_2_hostname)
  end

  include_examples "running ey scp"
  include_examples "running ey scp for select role"
end

describe "ey scp --db-servers" do
  before do
    @scp_flag = %w[--db-servers]
    @hosts = %w(db_master_hostname db_slave_1_hostname db_slave_2_hostname)
  end

  include_examples "running ey scp"
  include_examples "running ey scp for select role"
end

describe "ey scp --utilities" do
  before do
    @scp_flag = %w[--utilities]
    @hosts = %w(util_fluffy_hostname util_rocky_hostname)
  end

  include_examples "running ey scp"
  include_examples "running ey scp for select role"
end

describe "ey scp --utilities fluffy" do
  before do
    @scp_flag = %w[--utilities fluffy]
    @hosts = %w(util_fluffy_hostname)
  end

  include_examples "running ey scp"
  include_examples "running ey scp for select role"
end

describe "ey scp --utilities fluffy rocky" do
  before do
    @scp_flag = %w[--utilities fluffy rocky]
    @hosts = %w(util_fluffy_hostname util_rocky_hostname)
  end

  include_examples "running ey scp"
  include_examples "running ey scp for select role"
end

