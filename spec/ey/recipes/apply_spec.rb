require 'spec_helper'

describe "ey recipes apply" do
  given "integration"

  def command_to_run(opts)
    cmd = "recipes apply"
    cmd << " -e #{opts[:env]}" if opts[:env]
    cmd << " --account #{opts[:account]}" if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    @out.should =~ /Uploaded recipes started for #{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name and an account name"
end

describe "ey recipes apply with an ambiguous git repo" do
  given "integration"
  def command_to_run(_) "recipes apply" end
  it_should_behave_like "it requires an unambiguous git repo"
end
