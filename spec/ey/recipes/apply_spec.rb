require 'spec_helper'

describe "ey recipes apply" do
  it_should_behave_like "an integration test"

  before(:all) do
    api_scenario "one app, one environment"
  end

  it "works when the environment name is valid" do
    ey "recipes apply giblets", :debug => true
    @out.should =~ /Uploaded recipes started for giblets/i
  end

  it "runs recipes for the current environment by default" do
    ey "recipes apply", :debug => true
    @out.should =~ /Uploaded recipes started for giblets/i
  end

  it "fails when the environment name is bogus" do
    ey "recipes apply typo", :expect_failure => true
    @err.should match(/'typo'/)
  end
end

describe "ey recipes apply ENV" do
  it_should_behave_like "an integration test"

  before(:all) do
    api_scenario "one app, many similarly-named environments"
  end

  it "works when given an unambiguous substring" do
    ey "recipes apply prod", :debug => true
    @out.should =~ /Uploaded recipes started for railsapp_production/
  end

  it "complains when given an ambiguous substring" do
    ey "recipes apply staging", :hide_err => true, :expect_failure => true
    @err.should =~ /'staging' is ambiguous/
  end
end