begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  require "rubygems"; require "bundler"; Bundler.setup
end

# Bundled gems
require 'fakeweb'
require 'fakefs'

# Engineyard gem
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'engineyard'

# Spec stuff
require 'spec/autorun'
require 'support/helpers'

Spec::Runner.configure do |config|
  config.before(:all) do
    FakeWeb.allow_net_connect = false
    ENV["CLOUD_URL"] = "https://cloud.engineyard.com"
    ENV["NO_SSH"] = "true"
  end

  config.before(:each) do
    FakeFS::FileSystem.clear
  end
end
