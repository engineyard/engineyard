require 'spec_helper'

describe "ey logs" do
  before(:all) do
    ENV['CLOUD_URL'] = EY.fake_awsm
    FakeWeb.allow_net_connect = true

    FakeFS.deactivate!
    ENV['EYRC'] = "/tmp/eyrc"
    token = { ENV['CLOUD_URL'] => {
      "api_token" => "f81a1706ddaeb148cfb6235ddecfc1cf"} }
    File.open(ENV['EYRC'], "w"){|f| YAML.dump(token, f) }
  end

  after(:all) do
    ENV['CLOUD_URL'] = nil
    FakeFS.activate!
    FakeWeb.allow_net_connect = false
  end

  it "runs when environment is known" do
    api_scenario "one app, one environment"
    ey "logs giblets"
    @out.should match(/MAIN LOG OUTPUT/)
    @out.should match(/CUSTOM LOG OUTPUT/)
    @err.should be_empty
  end
end
