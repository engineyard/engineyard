require 'spec_helper'
require 'engineyard/cli'

describe EY::CLI do

  it "sets up EY.ui" do
    EY.instance_eval{ @ui = nil }
    EY.ui.should be_an(EY::UI)
    capture_stdout do
      EY::CLI.start(["help"])
    end
    EY.ui.should be_an(EY::CLI::UI)
  end

  it "provides help" do
    out = capture_stdout do
      EY::CLI.start(["help"])
    end

    out.should include("ey deploy")
    out.should include("ey ssh")
    out.should include("ey web enable")
  end

  it "delegates help" do
    out = capture_stdout do
      EY::CLI.start(%w[help web enable])
    end

    out.should match(/remove the maintenance page/i)
  end

  it "provides error classes" do
    EY::DeployArgumentError.should be
  end

end # EY::CLI
