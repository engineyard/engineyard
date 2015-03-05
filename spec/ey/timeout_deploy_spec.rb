require 'spec_helper'

describe "ey timeout-deploy" do
  given "integration"

  it "timeouts the last deployment" do
    login_scenario "Stuck Deployment"
    fast_ey %w[timeout-deploy]
    expect(@out).to match(/Marking last deployment failed.../)
    expect(@out).to match(/Finished at:\s+\w+/)
  end

  it "complains when there is no stuck deployment" do
    login_scenario "one app, one environment"
    fast_failing_ey ["timeout-deploy"]
    expect(@err).to include(%|No unfinished deployment was found for main / rails232app / giblets.|)
  end
end
