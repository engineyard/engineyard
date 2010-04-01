begin
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  require "rubygems"; require "bundler"; Bundler.setup
end

# Bundled gems
require 'fakeweb'
require 'fakefs/safe'

# Engineyard gem
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'engineyard'

# Spec stuff
require 'spec/autorun'
require 'support/helpers'

Spec::Runner.configure do |config|
  config.before(:all) do
    FakeWeb.allow_net_connect = false
    FakeFS.activate!
    ENV["CLOUD_URL"] = nil
    ENV["NO_SSH"] = "true"
  end

  config.before(:each) do
    FakeFS::FileSystem.clear
  end
end
