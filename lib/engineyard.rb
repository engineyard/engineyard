module EY
  require 'engineyard/ruby_ext'
  require 'engineyard/version'

  autoload :API,        'engineyard/api'
  autoload :Collection, 'engineyard/collection'
  autoload :Config,     'engineyard/config'
  autoload :Error,      'engineyard/error'
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
