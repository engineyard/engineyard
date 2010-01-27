$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'engineyard'

Bundler.require_env :test

require 'spec'
require 'spec/autorun'

require 'support/capture_stdout'

Spec::Runner.configure do |config|

end

FakeWeb.allow_net_connect = false
ENV["CLOUD_URL"] = "https://cloud.engineyard.com"