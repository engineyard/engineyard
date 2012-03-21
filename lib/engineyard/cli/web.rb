module EY
  class CLI
    class Web < EY::Thor
      desc "enable [--environment/-e ENVIRONMENT]",
        "Remove the maintenance page for this application in the given environment."
      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment on which to take down the maintenance page"
      method_option :app, :type => :string, :aliases => %w(-a),
        :desc => "Name of the application whose maintenance page will be removed"
      method_option :verbose, :type => :boolean, :aliases => %w(-v),
        :desc => "Be verbose"
      method_option :account, :type => :string, :aliases => %w(-c),
        :desc => "Name of the account in which the environment can be found"
      def enable
        app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
        EY.ui.info "Taking down maintenance page for '#{app_env.app.name}' in '#{app_env.environment.name}'"
        app_env.take_down_maintenance_page(options[:verbose])
      end

      desc "disable [--environment/-e ENVIRONMENT]",
        "Put up the maintenance page for this application in the given environment."
      long_desc <<-DESC
        The maintenance page is taken from the app currently being deployed. This means
        that you can customize maintenance pages to tell users the reason for downtime
        on every particular deploy.

        Maintenance pages searched for in order of decreasing priority:
        * public/maintenance.html.custom
        * public/maintenance.html.tmp
        * public/maintenance.html
        * public/system/maintenance.html.default
      DESC
      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment on which to put up the maintenance page"
      method_option :app, :type => :string, :aliases => %w(-a),
        :desc => "Name of the application whose maintenance page will be put up"
      method_option :verbose, :type => :boolean, :aliases => %w(-v),
        :desc => "Be verbose"
      method_option :account, :type => :string, :aliases => %w(-c),
        :desc => "Name of the account in which the environment can be found"
      def disable
        app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
        EY.ui.info "Putting up maintenance page for '#{app_env.app.name}' in '#{app_env.environment.name}'"
        app_env.put_up_maintenance_page(options[:verbose])
      end
    end
  end
end
