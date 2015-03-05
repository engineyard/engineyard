require 'spec_helper'
require 'engineyard/cli'

describe EY::CLI do

  it "provides help" do
    out = capture_stdout do
      EY::CLI.start(["help"])
    end

    expect(out).to include("ey deploy")
    expect(out).to include("ey ssh")
    expect(out).to include("ey web enable")
  end

  it "delegates help" do
    out = capture_stdout do
      EY::CLI.start(%w[help web enable])
    end

    expect(out).to match(/remove the maintenance page/i)
  end

  it "provides error classes" do
    expect(EY::DeployArgumentError).to be
  end

end # EY::CLI
