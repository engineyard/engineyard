require 'spec_helper'

describe "ey logout" do
  context "logged in" do
    given "integration"

    it "logs you out" do
      ey %w[logout]
      @out.should include("API token removed: #{ENV['EYRC']}")
      @out.should include("Run any other command to login again.")
    end
  end

  context "not logged in" do
    given "integration without an eyrc file"

    it "prompts for authentication before outputting the logged in user" do
      ey %w[logout]
      @out.should_not include("API token removed:")
      @out.should include("Already logged out.")
      @out.should include("Run any other command to login again.")
    end
  end
end
