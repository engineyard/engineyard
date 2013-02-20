require 'spec_helper'

describe "ey timeout-deploy" do
  given "integration"

  it "timeouts the last deployment" do
    login_scenario "Stuck Deployment"
    fast_ey %w[timeout-deploy]
    @out.should match(/Marking last deployment failed.../)
    @out.should match(/Finished at:\s+\w+/)
  end

  it "complains when there is no stuck deployment" do
    login_scenario "one app, one environment"
    fast_failing_ey ["timeout-deploy"]
    @err.should include(%|No unfinished deployment was found for main/rails232app/giblets.|)
  end
end
