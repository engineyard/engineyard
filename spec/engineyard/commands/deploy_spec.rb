require 'spec_helper'

describe "ey deploy" do
  it "gives usage information" do
    ey "deploy", :hide_err => true
    @err.should include %|"deploy" was called incorrectly|
  end
end