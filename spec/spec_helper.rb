# Bundled gems
require 'rubygems'
require 'bundler'
Bundler.require(:default, :development)

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
  end

  config.before(:each) do
    FakeFS::FileSystem.clear
  end
end
