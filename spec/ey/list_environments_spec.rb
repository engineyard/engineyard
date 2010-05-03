require 'spec_helper'

describe "ey environments" do
  it_should_behave_like "an integration test"

  before(:all) do
    api_scenario "one app, two environments"
  end

  it "lists the environments your app is in" do
    ey "environments"
    @out.should =~ /giblets/
    @out.should =~ /ham/
  end

end
