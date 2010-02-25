require 'spec_helper'

describe EY do
  it "provides error classes" do
    EY::Error.should be
    EY::EnvironmentError.should be
    EY::BranchMismatch.should be
  end

  it "provides an EY::API instance" do
    EY.api.should be_an(EY::API)
  end
end