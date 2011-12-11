require 'uri'
require 'engineyard/error'

module EY
  class Config
    CONFIG_FILES = ["config/ey.yml", "ey.yml"]

    def initialize(file = nil)
      require 'yaml'
      @file = file || CONFIG_FILES.find{|f| File.exists?(f) }
      @config = (@file ? YAML.load_file(@file) : {}) || {} # load_file returns `false' when the file is empty
      @config["environments"] = {} unless @config["environments"]
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
      @endpoint ||= env_var_endpoint || default_endpoint
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

    def default_branch(environment = default_environment)
      env = environments[environment]
      env && env["branch"]
    end

    private

    class ConfigurationError < EY::Error
      def initialize(key, value, source, message=nil)
        super %|"#{key}" from #{source} has invalid value: #{value.inspect}#{": #{message}" if message}|
      end
    end
  end
end
