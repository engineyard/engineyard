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

  it_should_behave_like "it takes an environment name"
end

describe "ey rollback ENV" do
  given "integration"

  before(:all) do
    api_scenario "one app, many similarly-named environments"
  end

  it "works when given an unambiguous substring" do
    ey "rollback prod", :debug => true
    @out.should match(/Rolling back railsapp_production/i)
    @err.should be_empty
    @ssh_commands.last.should match(/eysd deploy rollback --app rails232app/)
  end
end
