require 'engineyard'

module EY
  class CLI < Thor
    autoload :Token,   'engineyard/cli/token'
    autoload :UI, 'engineyard/cli/ui'

    include Thor::Actions

    def self.start
      EY.ui = EY::CLI::UI.new
      super
    end

    desc "deploy [ENVIRONMENT] [BRANCH]", "Deploy [BRANCH] of the app in the current directory to [ENVIRONMENT]"
    method_option :force, :type => :boolean, :aliases => %w(-f), :desc => "Force a deploy of the specified branch"
    method_option :migrate, :type => :boolean, :default => true, :aliases => %w(-m), :desc => "Run migrations after deploy"
    def deploy(env_name = nil, branch = nil)
      env_name ||= config.default_environment
      default_branch = config.default_branch(env_name)
      branch ||= (default_branch || repo.current_branch)

      if default_branch && (branch != default_branch) && !options[:force]
        raise BranchMismatch, %{Your deploy branch is set to "#{default_branch}".\n} +
        %{If you want to deploy branch "#{branch}", use --force.}
      end

      env = account.environments.find{|e| e["name"] == env_name }
      raise EnvironmentError, "No environment named '#{env_name}' running this app" unless env

      # OMG EY cloud quotes nulls when it returns JSON :(
      app_master = env["app_master"] != "null" && env["app_master"]
      raise EnvironmentError, "Your environment isn't running" unless app_master

      puts "ssh #{env["app_master"]} eysd deploy #{branch}"
    end


    desc "targets", "List environments that are deploy targets for the app in the current directory"
    def targets
      envs = account.environments_for_url(repo.url)
      if envs.empty?
        EY.ui.say %{You have no cloud environments set up for the repository "#{repo.url}".}
      else
        EY.ui.say %{Cloud environments for #{app["name"]}:}
        print_envs(envs)
      end
    end


    desc "environments", "All cloud environments"
    def environments
      envs = account.environments
      if envs.empty?
        EY.ui.say %{You do not have any cloud environments.}
      else
        EY.ui.say %{Cloud environments:}
        print_envs(envs)
      end
    end

  private

    def account
      @account ||= EY::Account.new(Token.new)
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def config
      @config ||= EY::Config.new
    end

    def print_envs(envs)
      # this should be a method of EY::Account::Environments or something eventually
      printable_envs = envs.map do |e|
        icount = e["instances_count"]
        iname = (icount == 1) ? "instance" : "instances"

        e["name"] << " (default)" if e["name"] == config.default_environment
        env = [e["name"]]
        env << "#{icount} #{iname}"
        env << e["apps"].inspect#map{|a| a["name"] }.join(", ")
      end
      EY.ui.print_table(printable_envs, :ident => 2)
    end
  end # CLI
end # EY
