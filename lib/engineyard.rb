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
    def debug(name, message=nil)
      if ENV['DEBUG']
        $stderr.puts message || name
      end
    end

    def info(*a) debug(*a); end
    def warn(*a) debug(*a); end
  end

  def self.ui
    @ui ||= UI.new
  end

  def self.ui=(ui)
    @ui = ui
  end

  def self.config
    @config ||= EY::Config.new(load_ey_yml_config)
  end

  CONFIG_FILES = ["config/ey.yml", "ey.yml"]

  def self.load_ey_yml_config
    file = CONFIG_FILES.detect { |f| repo.has_file?(f) }
    file && YAML.load(repo.read_file(file))
  rescue EY::Repo::NotAGitRepository => e
    EY.ui.warn "warn: Not a git repository: #{e.dir}"
    nil
  end

  def self.repo
    @repo ||= EY::Repo.new
  end

  def self.eyrc
    @eyrc ||= EY::EYRC.load
  end

  def self.reset
    @ui = @config = @eyrc = @repo = nil
  end
end
