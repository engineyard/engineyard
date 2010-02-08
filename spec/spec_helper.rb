$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'engineyard'

Bundler.require(:default, :test)

require 'spec'
require 'spec/autorun'

require 'support/helpers'

Spec::Runner.configure do |config|
  config.before(:each) do
    FakeFS::FileSystem.clear
  end
end

FakeWeb.allow_net_connect = false
ENV["CLOUD_URL"] = "https://cloud.engineyard.com"