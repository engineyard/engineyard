require 'spec_helper'

describe "ey rollback" do
  it_should_behave_like "an integration test"

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

  it "fails when the environment name is bogus" do
    ey "rollback typo", :expect_failure => true
    @err.should match(/'typo'/)
    @ssh_commands.should be_empty
  end
end

describe "ey rollback ENV" do
  it_should_behave_like "an integration test"

  before(:all) do
    api_scenario "one app, many similarly-named environments"
  end

  it "works when given an unambiguous substring" do
    ey "rollback prod", :debug => true
    @out.should match(/Rolling back railsapp_production/i)
    @err.should be_empty
    @ssh_commands.last.should match(/eysd deploy rollback --app rails232app/)
  end

  it "complains when given an ambiguous substring" do
    ey "rollback staging", :hide_err => true, :expect_failure => true
    @err.should =~ /'staging' is ambiguous/
    @ssh_commands.should be_empty
  end
end
