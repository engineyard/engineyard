require 'spec_helper'

describe "ey logs" do
  it_should_behave_like "an integration test"

  it "prints logs returned by awsm" do
    api_scenario "one app, one environment"
    ey "logs giblets"
    @out.should match(/MAIN LOG OUTPUT/)
    @out.should match(/CUSTOM LOG OUTPUT/)
    @err.should be_empty
  end
end
