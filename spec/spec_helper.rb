if self.class.const_defined?(:EY_ROOT)
  raise "don't require the spec helper twice!"
end

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

EY_ROOT = File.expand_path("../..", __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'escape'
require 'net/ssh'

# Bundled gems
require 'webmock/rspec'

require 'multi_json'

# Engineyard gem
$LOAD_PATH.unshift(File.join(EY_ROOT, "lib"))
require 'engineyard'

require 'engineyard-cloud-client/test'

# Spec stuff
require 'rspec'
require 'tmpdir'
require 'yaml'
require 'pp'

Dir[File.join(EY_ROOT,'/spec/support/*.rb')].each do |helper|
  require helper
end

TMPDIR = Pathname.new(__FILE__).dirname.parent.join('tmp')

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  config.include SpecHelpers
  config.include SpecHelpers::IntegrationHelpers

  config.extend SpecHelpers::GitRepoHelpers
  config.extend SpecHelpers::Given

  def clean_tmpdir
    TMPDIR.rmtree if TMPDIR.exist?
  end

  # Cleaning the tmpdir has to happen outside of the test cycle because git repos
  # last longer than the before/after :all test block in order to speed up specs.
  config.before(:suite) { clean_tmpdir }
  config.after(:suite) { clean_tmpdir }

  config.before(:all) do
    clean_eyrc
    WebMock.disable_net_connect!
    ENV["CLOUD_URL"] = nil
    ENV["NO_SSH"] = "true"
  end

  config.after(:all) do
    clean_eyrc
  end

end

shared_examples_for "integration" do
  use_git_repo('default')

  before(:all) do
    WebMock.allow_net_connect!
    ENV['CLOUD_URL'] = EY::CloudClient::Test::FakeAwsm.uri
  end

  after(:all) do
    ENV.delete('CLOUD_URL')
    WebMock.disable_net_connect!
  end
end
