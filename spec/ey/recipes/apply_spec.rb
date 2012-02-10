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

  include_examples "it takes an environment name and an account name"

  it "fails when given a bad option" do
    fast_failing_ey %w[web enable --lots --of --bogus --options]
    @err.should include("Unknown switches")
  end
end

describe "ey recipes apply with an ambiguous git repo" do
  given "integration"
  def command_to_run(_) %w[recipes apply] end
  include_examples "it requires an unambiguous git repo"
end
