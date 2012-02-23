require 'spec_helper'

describe "ey logout" do
  given "integration"

  context "logged in" do
    before { login_scenario 'empty' }

    it "logs you out" do
      ey %w[logout]
      @out.should include("API token removed: #{ENV['EYRC']}")
      @out.should include("Run any other command to login again.")
    end
  end

  context "not logged in" do
    it "doesn't prompt for login before logging out" do
      ey %w[logout]
      @out.should_not include("API token removed:")
      @out.should include("Already logged out.")
      @out.should include("Run any other command to login again.")
    end
  end
end
