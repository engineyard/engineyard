require 'spec_helper'

describe "ey whoami" do
  given "integration"

  context "logged in" do
    before { login_scenario 'empty' }
    it "outputs the currently logged in user" do
      ey %w[whoami]
      expect(@out).to include("User Name (#{scenario_email})")
    end
  end

  context "not logged in" do
    it "prompts for authentication before outputting the logged in user" do
      api_scenario 'empty'

      ey(%w[whoami], :hide_err => true) do |input|
        input.puts(scenario_email)
        input.puts(scenario_password)
      end

      expect(@out).to include("We need to fetch your API token; please log in.")
      expect(@out).to include("Email:")
      expect(@out).to include("Password:")

      expect(@out).to include("User Name (#{scenario_email})")
    end
  end
end
