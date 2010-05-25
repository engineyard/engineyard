if self.class.const_defined?(:EY_ROOT)
  raise "don't require the spec helper twice!"
end

EY_ROOT = File.expand_path("../..", __FILE__)
begin
  require File.join(EY_ROOT, ".bundle/environment.rb")
rescue LoadError
  puts "Can't load bundler environment. You need to run `bundle lock`."
  exit
end

# Bundled gems
require 'fakeweb'
require 'fakeweb_matcher'
require 'fakefs/safe'
require 'json'

# Engineyard gem
$LOAD_PATH.unshift(File.join(EY_ROOT, "lib"))
require 'engineyard'

# Spec stuff
require 'spec/autorun'
require 'yaml'
support = Dir[File.join(EY_ROOT,'/spec/support/*.rb')]
support.each{|helper| require helper }

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

shared_examples_for "an integration test without an eyrc file" do
  before(:all) do
    FakeFS.deactivate!
    ENV['EYRC'] = "/tmp/eyrc"
    FakeWeb.allow_net_connect = true
    ENV['CLOUD_URL'] = EY.fake_awsm
  end

  before(:each) do
    api_git_remote nil
  end

  after(:all) do
    ENV.delete('CLOUD_URL')
    ENV.delete('EYRC')
    FakeFS.activate!
    FakeWeb.allow_net_connect = false
  end
end

# Use this in conjunction with the 'ey' helper method
shared_examples_for "an integration test" do
  it_should_behave_like "an integration test without an eyrc file"

  before(:all) do
    token = { ENV['CLOUD_URL'] => {
        "api_token" => "f81a1706ddaeb148cfb6235ddecfc1cf"} }
    File.open(ENV['EYRC'], "w"){|f| YAML.dump(token, f) }
  end
end

shared_examples_for "it has an account" do
  before(:all) do
    @account = EY::Account.new(EY::API.new('asdf'))
  end
end
