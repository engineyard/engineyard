EY_ROOT = File.expand_path("../..", __FILE__)
begin
  require File.join(EY_ROOT, ".bundle/environment.rb")
rescue LoadError
  puts "Can't load bundler environment. You need to run `bundle lock`."
  exit
end

# Bundled gems
require 'fakeweb'
require 'fakefs/safe'

# Engineyard gem
$LOAD_PATH.unshift(File.join(EY_ROOT, "lib"))
require 'engineyard'

# Spec stuff
require 'spec/autorun'
require 'yaml'
support = Dir[File.join(EY_ROOT,'/spec/support/*.rb')]
support.each{|helper| require helper }

EY.start_fake_awsm

Spec::Runner.configure do |config|
  config.include Spec::Helpers

  config.before(:all) do
    FakeWeb.allow_net_connect = false
    FakeFS.activate!
    ENV["CLOUD_URL"] = nil
    ENV["NO_SSH"] = "true"
  end

  config.before(:each) do
    FakeFS::FileSystem.clear
    EY.instance_eval{ @config = nil }
  end
end

# Use this in conjunction with the 'ey' helper method
shared_examples_for "an integration test" do
  before(:all) do
    FakeFS.deactivate!
    ENV['EYRC'] = "/tmp/eyrc"
    ENV['CLOUD_URL'] = EY.fake_awsm
    FakeWeb.allow_net_connect = true

    token = { ENV['CLOUD_URL'] => {
        "api_token" => "f81a1706ddaeb148cfb6235ddecfc1cf"} }
    File.open(ENV['EYRC'], "w"){|f| YAML.dump(token, f) }
  end

  after(:all) do
    ENV['CLOUD_URL'] = nil
    FakeFS.activate!
    FakeWeb.allow_net_connect = false
  end
end
