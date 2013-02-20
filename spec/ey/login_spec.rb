require 'spec_helper'

describe "ey login" do
  given "integration"

  context "logged in" do
    before do
      login_scenario 'empty'
    end

    it "returns the logged in user name" do
      ey %w[login]
      @out.should include("User Name (#{scenario_email})")
    end
  end

  context "not logged in" do
    it "prompts for authentication before outputting the logged in user" do
      api_scenario "empty"

      ey(%w[login], :hide_err => true) do |input|
        input.puts(scenario_email)
        input.puts(scenario_password)
      end

      @out.should include("We need to fetch your API token; please log in.")
      @out.should include("Email:")
      @out.should include("Password:")

      @out.should include("User Name (#{scenario_email})")
    end
  end
end
