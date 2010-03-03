module EY
  class Config
    CONFIG_FILES = ["config/ey.yml", "ey.yml"]

    def initialize(file = nil)
      require 'yaml'
      file ||= CONFIG_FILES.find{|f| File.exists?(f) }
      @config = file ? YAML.load_file(file) : {}
      @config.merge!("environments" => {}) unless @config["environments"]
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
      @endpoint ||= (
        @config["endpoint"] ||
        ENV["CLOUD_URL"] ||
        default_endpoint
      ).chomp("/")
    end

    def default_endpoint
      "https://cloud.engineyard.com"
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
  end
end