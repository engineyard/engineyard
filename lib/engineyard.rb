module EY
  VERSION = "0.1"

  class Error < StandardError; end
  class EnvironmentError < Error; end
  class BranchMismatch < Error; end

  autoload :Account, 'engineyard/account'
  autoload :API,     'engineyard/api'
  autoload :Config,  'engineyard/config'
  autoload :Repo,    'engineyard/repo'
  autoload :Token,   'engineyard/token'
  autoload :UI,      'engineyard/ui'

  class << self
    attr_writer :ui

    def ui
      @ui ||= UI.new
    end

    def api
      @api ||= API.new(ENV["CLOUD_URL"])
    end

    def library(libname)
      begin
        require libname
      rescue LoadError
        unless @tried_rubygems
          require 'rubygems' rescue LoadError nil
          @tried_rubygems = true
          retry
        end
      end
    end

  end
end
