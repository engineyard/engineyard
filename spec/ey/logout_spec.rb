require 'spec_helper'

describe "ey logout" do
  given "integration"

  context "logged in" do
    before { login_scenario 'empty' }

    it "logs you out" do
      ey %w[logout]
      expect(@out).to include("API token removed: #{ENV['EYRC']}")
      expect(@out).to include("Run any other command to login again.")
    end
  end

  context "not logged in" do
    it "doesn't prompt for login before logging out" do
      ey %w[logout]
      expect(@out).not_to include("API token removed:")
      expect(@out).to include("Already logged out.")
      expect(@out).to include("Run any other command to login again.")
    end
  end
end
