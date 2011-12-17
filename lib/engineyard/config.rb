require 'uri'
require 'yaml'
require 'engineyard/error'

module EY
  class Config
    CONFIG_FILES = ["config/ey.yml", "ey.yml"].map {|path| Pathname.new(path)}.freeze

    attr_reader :path

    def initialize(file = nil)
      @path = file || CONFIG_FILES.find{|pathname| pathname.exist? }
      @config = (@path ? YAML.load_file(@path.to_s) : {}) || {} # load_file returns `false' when the file is empty
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
        env["default"]
      end
      d && d.first
    end

    def environment_config(environment_name)
      environments[environment_name] ||= {}
      EnvironmentConfig.new(environments[environment_name], environment_name, self)
    end

    def set_environment_option(environment_name, key, value)
      environments[environment_name] ||= {}
      environments[environment_name][key] = value
      ensure_path
      @path.open('w') do |f|
        YAML.dump(@config, f)
      end
    end

    def ensure_path
      return if @path && @path.exist?
      if !in_app_dir?
        raise "Not in application directory. Unable to save configuration."
      end
      @path = Pathname.new('config/ey.yml')
      @path.dirname.mkpath
      @path
    end

    # TODO HAX
    def in_app_dir?
      system('git rev-parse >/dev/null 2>&1')
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

      def fetch(key, default = nil, &block)
        if block
          @config.fetch(key.to_s, &block)
        else
          @config.fetch(key.to_s, default)
        end
      end

      def set(key, val)
        @config[key.to_s] = val
        @parent.set_environment_option(@name, key, val)
        val
      end

      def merge(other)
        to_clean_hash.merge(other)
      end

      def to_clean_hash
        @config.reject { |k,v| %w[branch migrate migration_command verbose].include?(k) }
      end

      def branch
        fetch('branch', nil)
      end

      def migrate(&block)
        fetch('migrate', &block)
      end

      def migrate=(mig)
        set('migrate', mig)
      end

      def migration_command
        fetch('migration_command', nil)
      end

      def migration_command=(cmd)
        set('migration_command', cmd)
      end
      alias migrate_command migration_command
      alias migrate_command= migration_command=

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
