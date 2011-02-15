require 'spec_helper'

describe "ey recipes download" do
  given "integration"
  use_git_repo('default')

  before(:each) do
    FileUtils.rm_rf('cookbooks')
  end

  after(:each) do
    # This test creates + destroys the cookbooks/ directory, thus
    # rendering the git repo unsuitable for reuse.
    refresh_git_repo('default')
  end

  def command_to_run(opts)
    cmd = %w[recipes download]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    @out.should =~ /Recipes downloaded successfully for #{scenario[:environment]}/
    File.read('cookbooks/README').should == "Remove this file to clone an upstream git repository of cookbooks\n"
  end

  it_should_behave_like "it takes an environment name and an account name"

  it "fails when cookbooks/ already exists" do
    api_scenario "one app, one environment"
    Dir.mkdir("cookbooks")
    ey %w[recipes download], :expect_failure => true
    @err.should match(/cookbooks.*already exists/i)
  end
end

describe "ey recipes download with an ambiguous git repo" do
  given "integration"
  def command_to_run(_) %w[recipes download] end
  it_should_behave_like "it requires an unambiguous git repo"
end
