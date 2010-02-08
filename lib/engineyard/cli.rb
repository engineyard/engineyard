$:.unshift File.expand_path('../../vendor', __FILE__)
require 'thor'
require 'engineyard'

module EY
  class CLI < Thor
    class UI < Thor::Base.shell; end
    def self.ui
      @ui ||= EY::CLI::UI.new
    end

    include Thor::Actions

    desc "deploy [ENVIRONMENT] [BRANCH]", "Deploy [BRANCH] of the app in the current directory to [ENVIRONMENT]"
    method_option :force, :type => :boolean, :aliases => %w(-f), :desc => "Force a deploy of the specified branch"
    method_option :migrate, :type => :boolean, :default => true, :aliases => %w(-m), :desc => "Run migrations after deploy"
    def deploy(environment = nil, branch = nil)
      environment ||= config.default_environment
      default_branch = config.default_branch(environment)
      branch ||= (default_branch || repo.current_branch)

      if default_branch && (branch != default_branch) && !options[:force]
        ui.say_status "Branch mismatch",
          %{Your deploy branch is set to "#{default_branch}".\n} +
          %{If you want to deploy branch "#{branch}", use --force.},
          :red
        raise Exit
      end

      require 'pp'
      pp environment
      pp branch
      pp default_branch
    end

    desc "targets", "List environments that are deploy targets for the app in the current directory"
    def targets
      envs = account.environments_for_url(repo.url)
      if envs.empty?
        ui.say %{You have no cloud environments set up for the repository "#{repo.url}".}
      else
        ui.say %{Cloud environments for #{app["name"]}:}
        print_envs(envs)
      end
    end

    desc "environments", "All cloud environments"
    def environments
      envs = account.environments
      if envs.empty?
        ui.say %{You do not have any cloud environments.}
      else
        ui.say %{Cloud environments:}
        print_envs(envs)
      end
    end

    class Exit < StandardError; end
  private

    def account
      @account ||= EY::Account.new(EY::Token.authenticate)
    end

    def repo
      @repo ||= EY::Repo.new
    end

    def config
      @config ||= EY::Config.new
    end

    def ui
      self.class.ui
    end

    def print_envs(envs)
      # this should be a method of EY::Account::Environments or something eventually
      envs.each do |e|
        icount = e["instances_count"]
        iname = (icount == 1) ? "instance" : "instances"
        env = "  #{e["name"]}, #{icount} #{iname}"
        env << " (default)" if e["name"] == config.default_environment
        ui.say env
      end
    end
  end # CLI
end # EY
