require 'erb'

module EY
  module Templates
    class EyYml
      PATH = Pathname.new(__FILE__).dirname.join('ey.yml.erb').freeze

      attr_reader :existing_config, :existing, :config, :template

      def initialize(existing, template=PATH)
        @template = template

        @existing        = existing.dup
        @environments    = @existing.delete('environments') || {}
        @existing_config = @existing.delete('defaults') || {}
        @config          = defaults.merge(@existing_config)

        fix_config!
      end

      def to_str
        ERB.new(template.read, 0, "<>").result(binding)
      end
      alias to_s to_str

      def write(dest)
        dest = Pathname.new(dest)
        dir  = dest.dirname
        temp = dir.join("ey.yml.tmp")

        # generate first so we don't overwrite with a failed generation
        output = to_str
        temp.open('w') { |f| f << output }

        FileUtils.mv(dest, dir.join("ey.yml.backup")) if dest.exist?
        FileUtils.mv(temp, dest)
      end

      protected

      def fix_config!
        if config['migrate'] == nil && existing_config['migration_command']
          config['migrate'] = true
        end
      end

      def defaults
        {
          "migrate"                         => Pathname.new('db/migrate').exist?,
          "migration_command"               => "rake db:migrate --trace",
          "precompile_assets"               => Pathname.new('app/assets').exist?,
          "precompile_assets_task"          => "assets:precompile",
          "asset_dependencies"              => nil, # %w[app/assets lib/assets vendor/assets Gemfile.lock config/application.rb config/routes.rb],
          "asset_strategy"                  => "shifting",
          "precompile_unchanged_assets"     => false,
          "bundle_without"                  => nil,
          "bundle_options"                  => nil,
          "maintenance_on_migrate"          => true,
          "maintenance_on_restart"          => nil,
          "verbose"                         => false,
          "ignore_database_adapter_warning" => false,
        }
      end

      def option_unless_default(key)
        value = config[key]
        if value != nil && value != defaults[key]
          option(key, value)
        else
          commented_option key
        end
      end

      def option(key, value = nil)
        value ||= config[key]
        dump_indented_yaml key => value
      end

      def commented_option(key)
        data = {key => defaults[key]}
        "  ##{dump_indented_yaml(data, 0)}"
      end

      def extra_root_options
        out = ""

        extra_defaults = config.reject { |k,v| defaults.key?(k) }
        extra_defaults.each do |key,val|
          out << option(key, val) << "\n"
        end

        unless existing.empty?
          out << dump_indented_yaml(existing, 0)
        end

        out
      end

      def environment_options
        if @environments && !@environments.empty?
          dump_indented_yaml(@environments)
        end
      end

      def dump_indented_yaml(data, indent=2)
        YAML.dump(data).sub(/^---/, '').lstrip.gsub(/^/,' '*indent)
      end

      def string_to_boolean(str)
        case str
        when "true"  then true
        when "false" then false
        else str
        end
      end

    end
  end
end
