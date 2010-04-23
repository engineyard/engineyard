module EY
  VERSION = "0.2.10.pre"

  autoload :Account, 'engineyard/account'
  autoload :API,     'engineyard/api'
  autoload :Config,  'engineyard/config'
  autoload :Repo,    'engineyard/repo'

  class Error < RuntimeError; end

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
