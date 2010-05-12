module EY
  require 'engineyard/ruby_ext'

  VERSION = "0.3.0"

  autoload :Account, 'engineyard/account'
  autoload :API,     'engineyard/api'
  autoload :Config,  'engineyard/config'
  autoload :Error,   'engineyard/error'
  autoload :Repo,    'engineyard/repo'

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
