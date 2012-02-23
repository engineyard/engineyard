require 'spec_helper'

describe "ey environments" do

  given "integration"

  before(:all) do
    login_scenario "one app, many environments"
  end

  it "outputs the status of the deployment" do
    ey %w[status -e giblets]
    @out.should =~ /Application:\s+rails232app/
    @out.should =~ /Environment:\s+giblets/
    @out.should =~ /Ref:\s+HEAD/
    @out.should =~ /Resolved Ref:\s+HEAD/
    @out.should =~ /Deployed by:\s+User Name/
    @out.should =~ /Started at:/
    @out.should =~ /Finished at:/
    @out.should =~ /This deployment was successful/
  end
end
