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

  it "lists all environments that have apps with -a" do
    ey "environments -a"
    @out.should include("bakon")
    @out.should include("giblets")
  end

  it "outputs simply with -s" do
    ey "environments -s"
    @out.split(/\n/).sort.should == ["bakon", "giblets"]
  end

  it "outputs all environments (including ones with no apps) simply with -a and -s" do
    ey "environments -a -s"
    @out.split(/\n/).sort.should == ["bakon", "beef", "giblets"]
  end

end
