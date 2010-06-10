require 'spec_helper'

describe "ey recipes apply" do
  given "integration"

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
end

describe "ey recipes apply" do
  given "integration"

  def command_to_run(opts)
    "recipes apply #{opts[:env]}"
  end

  def verify_ran(scenario)
    @out.should =~ /Uploaded recipes started for #{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name"
end
