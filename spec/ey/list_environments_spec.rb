require 'spec_helper'

describe "ey environments" do

  given "integration"

  context "with no apps" do
    before do
      login_scenario "empty"
    end

    it "suggests that you use environments --all" do
      fast_ey %w[environments]
      @out.should =~ /Use ey environments --all to see all environments./
    end
  end

  context "with apps" do
    before(:all) do
      login_scenario "one app, many environments"
    end

    it "lists the environments your app is in" do
      fast_ey %w[environments]
      @out.should include('main/rails232app')
      @out.should =~ /giblets/
      @out.should =~ /bakon/
    end

    it "reports failure to find a git repo when not in one" do
      Dir.chdir(Dir.tmpdir) do
        fast_failing_ey %w[environments]
        @err.should =~ /fatal: No git remotes found in .*#{Regexp.escape(Dir.tmpdir)}/
        @out.should_not =~ /no application configured/
      end
    end

    it "lists all environments that have apps with -a" do
      fast_ey %w[environments -a]
      @out.should include("bakon")
      @out.should include("giblets")
    end

    it "outputs simply with -s" do
      fast_ey %w[environments -s], :debug => false
      @out.split(/\n/).sort.should == ["bakon", "giblets"]
    end

    it "outputs all environments (including ones with no apps) simply with -a and -s" do
      fast_ey %w[environments -a -s], :debug => false
      @out.split(/\n/).sort.should == ["bakon", "beef", "giblets"]
    end
  end
end

describe "ey environments with an ambiguous git repo" do
  given "integration"
  include_examples "it has an ambiguous git repo"

  it "lists environments from all apps using the git repo" do
    fast_ey %w[environments]
    @out.should =~ /git repo matches multiple/i
    @out.should include("giblets")
    @out.should include("keycollector_production")
  end
end
