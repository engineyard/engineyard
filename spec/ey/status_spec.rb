require 'spec_helper'

describe "ey environments" do

  given "integration"

  before(:all) do
    login_scenario "one app, many environments"
  end

  it "tells you it's never been deployed" do
    fast_failing_ey %w[status -e giblets]
    expect(@err).to match(/Application rails232app has not been deployed on giblets./)
  end

  it "outputs the status of the deployment" do
    fast_ey %w[deploy -e giblets --ref HEAD --no-migrate]
    fast_ey %w[status -e giblets]
    expect(@out).to match(/Application:\s+rails232app/)
    expect(@out).to match(/Environment:\s+giblets/)
    expect(@out).to match(/Ref:\s+HEAD/)
    expect(@out).to match(/Resolved Ref:\s+resolved-HEAD/)
    expect(@out).to match(/Commit:\s+[a-f0-9]{40}/)
    expect(@out).to match(/Migrate:\s+false/)
    expect(@out).to match(/Deployed by:\s+One App Many Envs/)
    expect(@out).to match(/Started at:/)
    expect(@out).to match(/Finished at:/)
    expect(@out).to match(/Deployment was successful/)
  end

  it "quiets almost all of the output with --quiet" do
    fast_ey %w[deploy -e giblets --ref HEAD --no-migrate]
    fast_ey %w[status -e giblets -q]
    expect(@out).not_to match(/Application:\s+rails232app/)
    expect(@out).not_to match(/Environment:\s+giblets/)
    expect(@out).not_to match(/Ref:\s+HEAD/)
    expect(@out).not_to match(/Resolved Ref:\s+resolved-HEAD/)
    expect(@out).not_to match(/Commit:\s+[a-f0-9]{40}/)
    expect(@out).not_to match(/Migrate:\s+false/)
    expect(@out).not_to match(/Deployed by:\s+One App Many Envs/)
    expect(@out).not_to match(/Started at:/)
    expect(@out).not_to match(/Finished at:/)
    expect(@out).to match(/Deployment was successful/)
  end
end
