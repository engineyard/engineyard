require 'spec_helper'

describe "ey deploy" do
  it "gives usage information" do
    ey("deploy")
    @out.should include %|"deploy" was called incorrectly|
  end
end