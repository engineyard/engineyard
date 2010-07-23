require 'spec_helper'

describe "ey" do
  context "run without arguments" do
    it "prints usage information" do
      ey.should include("Usage:")
    end
  end

  context "run with an argument that is not a command" do
    it "tells the user that is not a command" do
      ey "foobarbaz", :expect_failure => true
      @err.should include("Could not find command")
    end
  end

  context "run a command and a bad flag" do
    it "tells the user that is not a valid flag" do
      ey "help --expect-failure", :expect_failure => true
      @err.should include("Unknown switches")
    end
  end
end
