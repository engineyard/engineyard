require 'uri'
require 'yaml'
require 'pathname'
require 'engineyard/error'

module EY
  class Config
    # This order is important.
    CONFIG_FILES = ["config/ey.yml", "ey.yml"].map {|path| Pathname.new(path)}.freeze
    TEMPLATE_PATHNAME = Pathname.new(__FILE__).dirname.join('templates','ey.yml').freeze

    def self.pathname_for_write
      pathname || CONFIG_FILES.find{|pathname| pathname.dirname.exist? }
    end

    def self.pathname
      CONFIG_FILES.find{|pathname| pathname.exist? }
    end

    def self.template_pathname
      TEMPLATE_PATHNAME
    end

    def self.load_config(path = pathname)
      config = YAML.load_file(path.to_s) if path && path.exist?
      config ||= {} # load_file returns `false' when the file is empty

      unless Hash === config
        raise "ey.yml load error: Expected a Hash but a #{config.class.name} was returned."
      end
      config
    end

    attr_reader :path

    def initialize(file = nil)
      @path = file ? Pathname.new(file) : self.class.pathname
      @config = self.class.load_config(@path)
      @config["environments"] ||= {}
    end

    def method_missing(meth, *args, &blk)
      key = meth.to_s.downcase
      if @config.key?(key)
        @config[key]
      else
        super
      end
    end

    def respond_to?(meth)
      key = meth.to_s.downcase
      @config.key?(key) || super
    end

    def fetch(key, default = nil, &block)
      block ? @config.fetch(key.to_s, &block) : @config.fetch(key.to_s, default)
    end

    def fetch_from_defaults(key, default=nil, &block)
      block ? defaults.fetch(key.to_s, &block) : defaults.fetch(key.to_s, default)
    end

    def [](key)
      @config[key.to_s.downcase]
    end

    def endpoint
      env_var_endpoint || default_endpoint
    end

    def env_var_endpoint
      ENV["CLOUD_URL"]
    end

    def default_endpoint
      "https://cloud.engineyard.com/"
    end

    def default_endpoint?
      default_endpoint == endpoint
    end

    def default_environment
      d = environments.find do |name, env|
        env && env["default"]
      end
      d && d.first
    end

    def defaults
      @config['defaults'] ||= {}
    end

    def environment_config(environment_name)
      environments[environment_name] ||= {}
      EnvironmentConfig.new(environments[environment_name], environment_name, self)
    end

    class EnvironmentConfig
      attr_reader :name

      def initialize(config, name, parent)
        @config = config || {}
        @name = name
        @parent = parent
      end

      def path
        @parent.path
      end

      def ensure_exists
        unless path && path.exist?
          raise EY::Error, "Please initialize this application with the following command:\n\tey init"
        end
      end

      def fetch(key, default = nil, &block)
        @config.fetch(key.to_s) do
          @parent.fetch_from_defaults(key.to_s, default, &block)
        end
      end

      def branch
        fetch('branch', nil)
      end

      def migrate
        ensure_exists
        fetch('migrate') do
          raise EY::Error, "'migrate' not found in #{path}. Reinitialize with:\n\tey init"
        end
      end

      def migration_command
        ensure_exists
        fetch('migration_command') do
          raise EY::Error, "'migration_command' not found in #{path}. Reinitialize with:\n\tey init"
        end
      end

      alias migrate_command migration_command

      def verbose
        fetch('verbose', false)
      end
    end

    private

    class ConfigurationError < EY::Error
      def initialize(key, value, source, message=nil)
        super %|"#{key}" from #{source} has invalid value: #{value.inspect}#{": #{message}" if message}|
      end
    end
  end
end
