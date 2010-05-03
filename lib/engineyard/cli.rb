require 'thor'
require 'engineyard'
require 'engineyard/error'

module EY
  class CLI < Thor
    autoload :API, 'engineyard/cli/api'
    autoload :UI,  'engineyard/cli/ui'

    include Thor::Actions

    def self.start(*)
      EY.ui = EY::CLI::UI.new
      super
    end

    desc "deploy [ENVIRONMENT] [BRANCH]", "Deploy [BRANCH] of the app in the current directory to [ENVIRONMENT]"
    method_option :force, :type => :boolean, :aliases => %w(-f),
      :desc => "Force a deploy of the specified branch"
    method_option :migrate, :type => :string, :aliases => %w(-m),
      :default => 'rake db:migrate',
      :desc => "Run migrations via [MIGRATE], defaults to 'rake db:migrate'; use --no-migrate to avoid running migrations"
    method_option :install_eysd, :type => :boolean, :aliases => %(-s),
      :desc => "Force remote install of eysd"
    def deploy(env_name = nil, branch = nil)
      require 'engineyard/action/deploy'
      EY::Action::Deploy.call(env_name, branch, options)
    end


    desc "environments [--all]", "List cloud environments for this app, or all environments"
    method_option :all, :type => :boolean, :aliases => %(-a)
    def environments
      require 'engineyard/action/list_environments'
      EY::Action::ListEnvironments.call(options[:all])
    end
    map "envs" => :environments


    desc "ssh ENV", "Open an ssh session to the environment's application server"
    def ssh(name)
      require 'engineyard/action/ssh'
      EY::Action::SSH.call(name)
    end

    desc "logs ENV", "Retrieve the latest logs for an enviornment"
    def logs(name)
      require 'engineyard/action/show_logs'
      EY::Action::ShowLogs.call(name)
    end

    desc "upload_recipes ENV", "Upload custom chef recipes from the current directory to ENV"
    def upload_recipes(name)
      require 'engineyard/action/upload_recipes'
      EY::Action::UploadRecipes.call(name)
    end

    desc "version", "Print the version of the engineyard gem"
    def version
      EY.ui.say %{engineyard version #{EY::VERSION}}
    end
    map "-v" => :version

  end # CLI
end # EY
