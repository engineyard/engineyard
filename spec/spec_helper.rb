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
require 'yaml'

Spec::Runner.configure do |config|
  config.before(:all) do
    FakeWeb.allow_net_connect = false
    FakeFS.activate!
    ENV["CLOUD_URL"] = nil
    ENV["NO_SSH"] = "true"
  end

  config.before(:each) do
    EY.config = nil
    FakeFS::FileSystem.clear
  end

  def load_config(file="ey.yml")
    YAML.load_file(File.expand_path(file))
  end

  def write_config(data, file = "ey.yml")
    File.open(file, "w"){|f| YAML.dump(data, f) }
  end
end
