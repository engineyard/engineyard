require 'spec_helper'

describe "ey rebuild" do
  it_should_behave_like "an integration test"

  before(:each) do
    api_scenario "one app, one environment"
  end

  it "works when the environment name is valid" do
    ey "rebuild giblets"
    @out.should =~ /Rebuilding giblets/i
  end

  it "rebuilds the current environment by default" do
    ey "rebuild"
    @out.should =~ /Rebuilding giblets/i
  end

  it "fails when the environment name is bogus" do
    ey "rebuild typo", :expect_failure => true
    @err.should match(/No environment named 'typo'/)
  end
end

