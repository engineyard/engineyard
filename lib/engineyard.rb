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

  class << self
    attr_accessor :ui

    def ui
      @ui ||= UI.new
    end

    def config
      @config ||= EY::Config.new
    end

  end
end
