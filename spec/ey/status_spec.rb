require 'spec_helper'

describe "ey environments" do

  given "integration"

  before(:all) do
    login_scenario "one app, many environments"
  end

  it "tells you it's never been deployed" do
    fast_failing_ey %w[status -e giblets]
    @err.should =~ /Application rails232app has not been deployed on giblets./
  end

  it "outputs the status of the deployment" do
    fast_ey %w[deploy -e giblets --ref HEAD --no-migrate]
    fast_ey %w[status -e giblets]
    @out.should =~ /Application:\s+rails232app/
    @out.should =~ /Environment:\s+giblets/
    @out.should =~ /Ref:\s+HEAD/
    @out.should =~ /Resolved Ref:\s+resolved-HEAD/
    @out.should =~ /Commit:\s+[a-f0-9]{40}/
    @out.should =~ /Migrate:\s+false/
    @out.should =~ /Deployed by:\s+One App Many Envs/
    @out.should =~ /Started at:/
    @out.should =~ /Finished at:/
    @out.should =~ /This deployment was successful/
  end
end
