require 'spec_helper'

describe "ey rebuild" do
  it_should_behave_like "an integration test"

  before(:all) do
    api_scenario "one app, one environment"
  end

  it "works when the environment name is valid" do
    ey "rebuild giblets", :debug => true
    @out.should =~ /Rebuilding giblets/i
  end

  it "rebuilds the current environment by default" do
    ey "rebuild", :debug => true
    @out.should =~ /Rebuilding giblets/i
  end

  it "fails when the environment name is bogus" do
    ey "rebuild typo", :expect_failure => true
    @err.should match(/No environment named 'typo'/)
  end
end

describe "ey rebuild ENV" do
  it_should_behave_like "an integration test"

  before(:all) do
    api_scenario "one app, many similarly-named environments"
  end

  it "works when given an unambiguous substring" do
    ey "rebuild prod", :debug => true
    @out.should =~ /Rebuilding railsapp_production/
  end

  it "complains when given an ambiguous substring" do
    ey "rebuild staging", :hide_err => true, :expect_failure => true
    @err.should =~ /'staging' is ambiguous/
  end
end
