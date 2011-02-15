require 'spec_helper'

describe "ey recipes apply" do
  given "integration"

  def command_to_run(opts)
    cmd = %w[recipes apply]
    cmd << "-e"        << opts[:environment] if opts[:environment]
    cmd << "--account" << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    @out.should =~ /Uploaded recipes started for #{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name and an account name"

  it "fails when given a bad option" do
    ey %w[web enable --lots --of --bogus --options], :expect_failure => true
    @err.should include("Unknown switches")
  end
end

describe "ey recipes apply with an ambiguous git repo" do
  given "integration"
  def command_to_run(_) %w[recipes apply] end
  it_should_behave_like "it requires an unambiguous git repo"
end
