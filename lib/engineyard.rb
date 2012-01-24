thor_lib = File.expand_path(File.join(File.dirname(__FILE__), 'vendor', 'thor', 'lib'))
$:.unshift thor_lib

module EY
  require 'engineyard/ruby_ext'
  require 'engineyard/version'
  require 'engineyard/error'
  require 'engineyard/config'

  autoload :API,        'engineyard/api'
  autoload :Collection, 'engineyard/collection'
  autoload :Model,      'engineyard/model'
  autoload :Repo,       'engineyard/repo'
  autoload :Resolver,   'engineyard/resolver'

  class UI
    # stub debug outside of the CLI
    def debug(*); end
  end

  def self.ui
    @ui ||= UI.new
  end

  def self.ui=(ui)
    @ui = ui
  end

  def self.config
    @config ||= EY::Config.new
  end
end
