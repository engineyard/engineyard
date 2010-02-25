require 'spec_helper'
require 'engineyard/cli'

describe EY::CLI do

  it "should set up EY.ui" do
    EY.ui.should be_an(EY::UI)
    capture_stdout do
      EY::CLI.start(["help"])
    end
    EY.ui.should be_an(EY::CLI::UI)
  end

end # EY::CLI
