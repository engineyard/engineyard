require 'spec_helper'

describe "ey logs" do
  given "integration"

  it "prints logs returned by awsm" do
    api_scenario "one app, one environment"
    ey "logs giblets"
    @out.should match(/MAIN LOG OUTPUT/)
    @out.should match(/CUSTOM LOG OUTPUT/)
    @err.should be_empty
  end

  it "complains when it can't infer the environment" do
    api_scenario "one app, two environments"
    ey "logs", :expect_failure => true
    @err.should =~ /single environment/
  end
end

describe "ey logs" do
  given "integration"

  def command_to_run(opts)
    "logs #{opts[:env]}"
  end

  def verify_ran(scenario)
    @out.should match(/Main logs for #{scenario[:environment]}/)
  end

  it_should_behave_like "it takes an environment name"
end
