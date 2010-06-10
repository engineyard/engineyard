require 'spec_helper'

describe "ey rollback" do
  given "integration"

  before(:all) do
    api_scenario "one app, one environment"
  end

  it "works when the environment name is valid" do
    ey "rollback giblets", :debug => true
    @out.should match(/rolling back giblets/i)
    @err.should be_empty
    @ssh_commands.last.should match(/eysd deploy rollback --app rails232app/)
  end

  it "rollback the current environment by default" do
    ey "rollback", :debug => true
    @out.should match(/rolling back giblets/i)
    @err.should be_empty
    @ssh_commands.last.should match(/eysd deploy rollback --app rails232app/)
  end
end

describe "ey rollback" do
  given "integration"

  def command_to_run(opts)
    "rollback #{opts[:env]}"
  end

  def verify_ran(scenario)
    @out.should match(/Rolling back #{scenario[:environment]}/)
    @err.should be_empty
    @ssh_commands.last.should match(/eysd deploy rollback --app #{scenario[:application]}/)
  end

  it_should_behave_like "it takes an environment name"
end
