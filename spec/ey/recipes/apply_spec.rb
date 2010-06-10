require 'spec_helper'

describe "ey recipes apply" do
  given "integration"

  def command_to_run(opts)
    "recipes apply #{opts[:env]}"
  end

  def verify_ran(scenario)
    @out.should =~ /Uploaded recipes started for #{scenario[:environment]}/
  end

  it_should_behave_like "it takes an environment name"
end
