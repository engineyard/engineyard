require 'engineyard-api-client'

module EY
  require 'engineyard/version'
  require 'engineyard/error'
  require 'engineyard/config'

  autoload :Repo,       'engineyard/repo'

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
