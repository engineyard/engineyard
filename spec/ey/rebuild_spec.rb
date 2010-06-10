require 'spec_helper'

describe "ey rebuild" do
  given "integration"

  def command_to_run(opts)
    "rebuild #{opts[:env]}"
  end

  def verify_ran(scenario)
    @out.should =~ /Rebuilding #{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name"
end
