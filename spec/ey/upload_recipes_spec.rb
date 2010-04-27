require 'spec_helper'

describe "ey upload_recipes" do
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

  it "posts the recipes to the correct url" do
    api_scenario "one app, one environment"
    dir = Pathname.new("/tmp/#{$$}")
    dir.mkdir
    Dir.chdir(dir) do
      dir.join("cookbooks").mkdir
      File.open(dir.join("cookbooks/file"), "w"){|f| f << "boo" }
      `git init`
      `git add .`
      `git commit -m "OMG"`
      ey "upload_recipes giblets", :debug => true
    end
    @out.should =~ /recipes uploaded successfully/i
  end
end
