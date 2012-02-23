require 'spec_helper'

describe "ey whoami" do
  given "integration"

  context "logged in" do
    before { login_scenario 'empty' }
    it "outputs the currently logged in user" do
      ey %w[whoami]
      @out.should include("User Name (#{scenario_email})")
    end
  end

  context "not logged in" do
    it "prompts for authentication before outputting the logged in user" do
      api_scenario 'empty'

      ey(%w[whoami], :hide_err => true) do |input|
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
