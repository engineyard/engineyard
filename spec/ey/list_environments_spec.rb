require 'spec_helper'

describe "ey environments" do

  given "integration"

  before(:all) do
    api_scenario "one app, many environments"
  end

  it "lists the environments your app is in" do
    ey "environments"
    @out.should =~ /giblets/
    @out.should =~ /bakon/
  end

  it "reports failure to find a git repo when not in one" do
    Dir.chdir("/tmp") do
      ey "environments", :expect_failure => true
      @err.should =~ /fatal: No git remotes found in .*\/tmp/
      @out.should_not =~ /no application configured/
    end
  end

end
