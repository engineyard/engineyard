module EY
  VERSION = "0.1"

  autoload :Account, 'engineyard/account'
  autoload :Config,  'engineyard/config'
  autoload :Repo,    'engineyard/repo'
  autoload :Request, 'engineyard/request'
  autoload :Token,   'engineyard/token'
  autoload :UI,      'engineyard/ui'

  class << self
    def ui
      @ui ||= UI.new
    end

    def library(libname)
      unless @tried_gems
        require 'rubygems' rescue LoadError nil
        @tried_gems = true
      end
      require libname
    end
  end
end
