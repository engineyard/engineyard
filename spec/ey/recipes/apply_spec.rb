require 'spec_helper'

describe "ey recipes apply" do
  given "integration"

  def command_to_run(opts)
    cmd = "recipes apply"
    cmd << " -e #{opts[:env]}" if opts[:env]
    cmd
  end

  def verify_ran(scenario)
    @out.should =~ /Uploaded recipes started for #{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name"
end
