require 'uri'
require 'yaml'
require 'pathname'
require 'engineyard/error'

module EY
  class Config
    CONFIG_FILES = ["config/ey.yml", "ey.yml"].map {|path| Pathname.new(path)}.freeze

    attr_reader :path

    def initialize(file = nil)
      @path = file ? Pathname.new(file) : CONFIG_FILES.find{|pathname| pathname.exist? }
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
        env["default"]
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

    def set_environment_option(environment_name, key, value)
      environments[environment_name] ||= {}
      environments[environment_name][key] = value
      write_ey_yaml
    end

    def write_ey_yaml
      ensure_path
      comments = ey_yml_comments
      @path.open('w') do |f|
        f.puts comments
        f.puts YAML.dump(@config)
      end
    end

    def set_default_option(key, value)
      defaults[key] = value
      write_ey_yaml
    end

    EY_YML_HINTS = <<-HINTS
# ey.yml supports many deploy configuration options when committed in an
# application's repository.
#
# Valid locations: REPO_ROOT/ey.yml or REPO_ROOT/config/ey.yml.
#
# Examples options (defaults apply to all environments for this application):
#
# defaults:
#   migrate: true                           # Default --migrate choice for ey deploy
#   migration_command: 'rake migrate'       # Default migrate command to run when migrations are enabled
#   branch: default_deploy_branch           # Branch/ref to be deployed by default during ey deploy
#   bundle_without: development test        # The string to pass to bundle install --without ''
#   maintenance_on_migrate: true            # Enable maintenance page during migrate action (use with caution) (default: true)
#   maintenance_on_restart: false           # Enable maintanence page during every deploy (default: false for unicorn & passenger)
#   ignore_database_adapter_warning: false  # Hide the warning shown when the Gemfile does not contain a recognized database adapter (mongodb for example)
#   your_own_custom_key: 'any attribute you put in ey.yml is available in deploy hooks'
# environments:
#   YOUR_ENVIRONMENT_NAME: # All options pertain only to the named environment
#     any_option: 'override any of the options above with specific options for certain environments'
#     migrate: false
#
# Further information available here:
# https://support.cloud.engineyard.com/entries/20996661-customize-your-deployment-on-engine-yard-cloud
#
# NOTE: Please commit this file into your git repository.
#
    HINTS

    def ey_yml_comments
      if @path.exist?
        existing = @path.readlines.grep(/^#/).map {|line| line.strip }.join("\n")
      else
        EY_YML_HINTS
      end
    end

    def ensure_path
      return if @path && @path.exist?
      unless EY::Repo.exist?
        raise "Not in application directory. Unable to save configuration."
      end
      if Pathname.new('config').exist?
        @path = Pathname.new('config/ey.yml')
      else
        @path = Pathname.new('ey.yml')
      end
      @path
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
        @config.fetch(key.to_s) do
          @parent.fetch_from_defaults(key.to_s, default, &block)
        end
      end

      def set(key, val)
        if @config.empty? || !@config.has_key?(key.to_s)
          @parent.set_default_option(key, val)
        else
          @config[key.to_s] = val
          @parent.set_environment_option(@name, key, val)
        end
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

      def migrate
        fetch('migrate')
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
