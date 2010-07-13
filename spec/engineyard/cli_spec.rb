require 'spec_helper'
require 'engineyard/cli'

describe EY::CLI do

  it "sets up EY.ui" do
    EY.ui.should be_an(EY::UI)
    capture_stdout do
      EY::CLI.start(["help"])
    end
    EY.ui.should be_an(EY::CLI::UI)
  end

  it "provides error classes" do
    EY::EnvironmentError.should be
    EY::BranchMismatchError.should be
    EY::DeployArgumentError.should be
  end

end # EY::CLI
