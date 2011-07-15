require 'spec_helper'

describe "ey environments" do

  given "integration"

  context "with no apps" do
    before do
      api_scenario "empty"
    end

    it "suggests that you use environments --all" do
      ey %w[environments]
      @out.should =~ /Use ey environments --all to see all environments./
    end
  end

  context "with apps" do
    before(:all) do
      api_scenario "one app, many environments"
    end

    it "lists the environments your app is in" do
      ey %w[environments]
      @out.should include('rails232app (main)')
      @out.should =~ /giblets/
      @out.should =~ /bakon/
    end

    it "reports failure to find a git repo when not in one" do
      Dir.chdir("/tmp") do
        ey %w[environments], :expect_failure => true
        @err.should =~ /fatal: No git remotes found in .*\/tmp/
        @out.should_not =~ /no application configured/
      end
    end

    it "lists all environments that have apps with -a" do
      ey %w[environments -a]
      @out.should include("bakon")
      @out.should include("giblets")
    end

    it "outputs simply with -s" do
      ey %w[environments -s], :debug => false
      @out.split(/\n/).sort.should == ["bakon", "giblets"]
    end

    it "outputs all environments (including ones with no apps) simply with -a and -s" do
      ey %w[environments -a -s], :debug => false
      @out.split(/\n/).sort.should == ["bakon", "beef", "giblets"]
    end
  end
end

describe "ey environments with an ambiguous git repo" do
  given "integration"
  it_should_behave_like "it has an ambiguous git repo"

  it "lists environments from all apps using the git repo" do
    ey %w[environments]
    @out.should =~ /git repo matches multiple/i
    @out.should include("giblets")
    @out.should include("keycollector_production")
  end
end
