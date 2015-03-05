require 'spec_helper'

describe "ey" do
  context "run without arguments" do
    it "prints usage information" do
      expect(ey).to include("Usage:")
    end
  end

  context "run with an argument that is not a command" do
    it "tells the user that is not a command" do
      ey %w[foobarbaz], :expect_failure => true
      expect(@err).to include("Could not find command")
    end
  end

  context "run a command and a bad flag" do
    it "tells the user that is not a valid flag" do
      ey %w[help --expect-failure], :expect_failure => true
      expect(@err).to include("Unknown switches")
    end
  end
end
