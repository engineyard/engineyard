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

require 'json'

# Engineyard gem
$LOAD_PATH.unshift(File.join(EY_ROOT, "lib"))
require 'engineyard'

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

  def clean_eyrc
    ENV['EYRC'] = File.join('/tmp','eyrc')
    if File.exist?(ENV['EYRC'])
      File.unlink(ENV['EYRC'])
    end
  end

  config.before(:all) do
    FakeWeb.allow_net_connect = false
    ENV["NO_SSH"] = "true"
  end

  config.before(:each) do
    ENV['CLOUD_URL'] ||= 'http://fake.local/'
    clean_eyrc
    EY.reset
  end
end

EY.define_git_repo("default") do |git_dir|
  system("echo 'source :gemcutter' > Gemfile")
  system("git add Gemfile")
  system("git commit -m 'initial commit' >/dev/null 2>&1")
end

shared_examples_for "integration without an eyrc file" do
  before(:all) do
    FakeWeb.allow_net_connect = true
    ENV['CLOUD_URL'] = EY.fake_awsm
  end

  after(:all) do
    ENV.delete('CLOUD_URL')
    FakeWeb.allow_net_connect = false
  end

  use_git_repo('default')
end

# Use this in conjunction with the 'ey' helper method
shared_examples_for "integration" do
  given "integration without an eyrc file"

  before(:each) do
    write_eyrc({"api_token" => "f81a1706ddaeb148cfb6235ddecfc1cf"})
  end
end
