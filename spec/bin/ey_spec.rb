require 'spec_helper'

describe "ey binary" do
  context "run without arguments" do
    it "prints usage information" do
      ey.should include "usage"
    end
  end

  context "run with an argument that is not a command" do
    before(:all) do
      ey("foobarbaz")
    end

    it "tells the user that is not a command" do
      @out.should include "Command not found"
    end

    it "prints usage information" do
      @out.should include "usage"
    end
  end
end