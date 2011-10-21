if self.class.const_defined?(:EY_ROOT)
  raise "don't require the spec helper twice!"
end

EY_ROOT = File.expand_path("../..", __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'escape'
require 'net/ssh'

# Bundled gems
require 'fakeweb'
require 'fakeweb_matcher'
require 'fakefs/safe'
module FakeFS
  def self.activated?
    Object.const_get(:Dir) == FakeFS::Dir
  end

  def self.without
    was_on = activated?
    deactivate!
    yield
    activate! if was_on
  end
end

require 'json'

# Engineyard gem
$LOAD_PATH.unshift(File.join(EY_ROOT, "lib"))
require 'engineyard'

#autoload hax
EY::Error

# Spec stuff
require 'rspec'
require 'tmpdir'
require 'yaml'
require 'pp'
support = Dir[File.join(EY_ROOT,'/spec/support/*.rb')]
support.each{|helper| require helper }

RSpec.configure do |config|
  config.include SpecHelpers
  config.include SpecHelpers::IntegrationHelpers

  config.extend SpecHelpers::GitRepoHelpers
  config.extend SpecHelpers::Given
  config.extend SpecHelpers::Fixtures

  config.before(:all) do
    FakeWeb.allow_net_connect = false
    FakeFS.activate!
    ENV["CLOUD_URL"] = nil
    ENV["NO_SSH"] = "true"
  end

  config.before(:each) do
    FakeFS::FileSystem.clear
    FakeFS::FileSystem.add(ENV['HOME'])
    EY.instance_eval{ @config = nil }
  end
end

EY.define_git_repo("default") do |git_dir|
  system("echo 'source :gemcutter' > Gemfile")
  system("git add Gemfile")
  system("git commit -m 'initial commit' >/dev/null 2>&1")
end

shared_examples_for "integration without an eyrc file" do
  use_git_repo('default')

  before(:all) do
    FakeFS.deactivate!
    ENV['EYRC'] = "/tmp/eyrc"
    FakeWeb.allow_net_connect = true
    ENV['CLOUD_URL'] = EY.fake_awsm
  end

  after(:all) do
    ENV.delete('CLOUD_URL')
    ENV.delete('EYRC')
    FakeFS.activate!
    FakeWeb.allow_net_connect = false
  end
end

# Use this in conjunction with the 'ey' helper method
shared_examples_for "integration" do
  given "integration without an eyrc file"

  before(:all) do
    token = { ENV['CLOUD_URL'] => {
        "api_token" => "f81a1706ddaeb148cfb6235ddecfc1cf"} }
    File.open(ENV['EYRC'], "w"){|f| YAML.dump(token, f) }
  end
end
