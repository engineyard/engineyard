require 'spec_helper'

describe "ey environments" do

  given "integration"

  before { @succeeds_on_multiple_matches = true }

  def command_to_run(opts)
    cmd = ["environments"]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--app"         << opts[:app]         if opts[:app]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/#{scenario[:environment]}/) if scenario[:environment]
    @out.should match(/#{scenario[:application]}/) if scenario[:application]
  end

  include_examples "it takes an environment name and an app name and an account name"

  context "with no apps" do
    before do
      login_scenario "empty"
    end

    it "suggests that you use environments --all" do
      fast_failing_ey %w[environments]
      @err.should =~ /Use ey environments --all to see all environments./
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

    it "lists the environments with specified app" do
      fast_ey %w[environments --app rails232app]
      @out.should include('main/rails232app')
      @out.should =~ /giblets/
      @out.should =~ /bakon/
    end

    it "finds no environments with gibberish app" do
      fast_failing_ey %w[environments --account main --app gibberish]
      @err.should =~ /Use ey environments --all to see all environments./
    end

    it "finds no environments with gibberish account" do
      fast_failing_ey %w[environments --account gibberish --app rails232]
      @err.should =~ /Use ey environments --all to see all environments./
    end

    it "lists the environments that the app is in" do
      fast_ey %w[environments --app rails232app]
      @out.should include('main/rails232app')
      @out.should =~ /giblets/
      @out.should =~ /bakon/
    end

    it "lists the environments that the app is in" do
      fast_ey %w[environments --account main]
      @out.should include('main/rails232app')
      @out.should =~ /giblets/
      @out.should =~ /bakon/
    end

    it "lists the environments matching --environment" do
      fast_ey %w[environments -e gib]
      @out.should include('main/rails232app')
      @out.should =~ /giblets/
      @out.should_not =~ /bakon/
    end

    it "reports failure to find a git repo when not in one" do
      Dir.chdir(Dir.tmpdir) do
        fast_failing_ey %w[environments]
        @err.should =~ /fatal: Not a git repository \(or any of the parent directories\): .*#{Regexp.escape(Dir.tmpdir)}/
        @out.should_not =~ /no application configured/
      end
    end

    it "lists all environments that have apps with -A" do
      fast_ey %w[environments -A]
      @out.should include("bakon")
      @out.should include("giblets")
    end

    it "outputs simply with -s" do
      fast_ey %w[environments -s], :debug => false
      @out.split(/\n/).sort.should == ["bakon", "giblets"]
    end

    it "outputs all environments (including ones with no apps) simply with -A and -s" do
      fast_ey %w[environments -A -s], :debug => false
      @out.split(/\n/).sort.should == ["bakon", "beef", "giblets"]
    end
  end
end

describe "ey environments with an ambiguous git repo" do
  given "integration"
  include_examples "it has an ambiguous git repo"

  it "lists environments from all apps using the git repo" do
    fast_ey %w[environments]
    @out.should include("giblets")
    @out.should include("keycollector_production")
  end
end
