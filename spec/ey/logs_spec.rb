require 'spec_helper'

describe "ey logs" do
  given "integration"

  it "prints logs returned by awsm" do
    login_scenario "one app, one environment"
    fast_ey %w[logs -e giblets]
    expect(@out).to match(/MAIN LOG OUTPUT/)
    expect(@out).to match(/CUSTOM LOG OUTPUT/)
    expect(@err).to eq('')
  end

  it "complains when it can't infer the environment" do
    login_scenario "one app, many environments"
    fast_failing_ey %w[logs]
    expect(@err).to match(/Multiple environments possible, please be more specific/i)
  end
end

describe "ey logs" do
  given "integration"

  def command_to_run(opts)
    cmd = ["logs"]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    expect(@out).to match(/Main logs for #{scenario[:environment]}/)
  end

  include_examples "it takes an environment name and an account name"
end
