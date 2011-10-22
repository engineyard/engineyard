require 'engineyard/ruby_ext'

module EY
end

require 'engineyard/config'

module EY
  class UI
    # stub debug outside of the CLI
    def debug(*); end
  end

  def self.ui
    @ui ||= UI.new
  end

  def self.ui=(new_ui)
    @ui = new_ui
  end

  def self.config
    @config ||= EY::Config.new
  end
end
