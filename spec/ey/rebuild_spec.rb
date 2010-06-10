require 'spec_helper'

describe "ey rebuild" do
  given "integration"

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
end

describe "ey rebuild" do
  given "integration"

  def command_to_run(opts)
    "rebuild #{opts[:env]}"
  end

  def verify_ran(scenario)
    @out.should =~ /Rebuilding #{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name"
end
