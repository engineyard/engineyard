require 'spec_helper'

describe "ey rebuild" do
  given "integration"

  def command_to_run(opts)
    cmd = "rebuild"
    cmd << " --environment #{opts[:environment]}" if opts[:environment]
    cmd << " --account #{opts[:account]}" if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    @out.should =~ /Rebuilding #{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name and an account name"
end
