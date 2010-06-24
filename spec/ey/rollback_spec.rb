require 'spec_helper'

describe "ey rollback" do
  given "integration"

  def command_to_run(opts)
    cmd = "rollback"
    cmd << " -e #{opts[:env]}" if opts[:env]
    cmd << " -a #{opts[:app]}" if opts[:app]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/Rolling back #{scenario[:environment]}/)
    @err.should be_empty
    @ssh_commands.last.should match(/eysd.*deploy rollback.*--app #{scenario[:application]}/)
  end

  it_should_behave_like "it takes an environment name"
  it_should_behave_like "it takes an app name"
  it_should_behave_like "it invokes eysd"

  it "passes along the web server stack to eysd" do
    api_scenario "one app, one environment"
    ey "rollback"
    @ssh_commands.last.should =~ /--stack nginx_mongrel/
  end

end
