module EY
  class CLI
    class Web < EY::Thor
      desc "enable [--environment/-e ENVIRONMENT]",
        "Remove the maintenance page for this application in the given environment."
      method_option :environment, :type => :string, :aliases => %w(-e),
        :required => true, :default => '',
        :desc => "Environment on which to take down the maintenance page"
      method_option :app, :type => :string, :aliases => %w(-a),
        :required => true, :default => '',
        :desc => "Name of the application whose maintenance page will be removed"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the environment can be found"
      method_option :verbose, :type => :boolean, :aliases => %w(-v),
        :desc => "Be verbose"
      def enable
        app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
        ui.info "Taking down maintenance page for '#{app_env.app.name}' in '#{app_env.environment.name}'"
        serverside_runner(app_env, options[:verbose]).take_down_maintenance_page.call(ui.out, ui.err)
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
        :required => true, :default => '',
        :desc => "Environment on which to put up the maintenance page"
      method_option :app, :type => :string, :aliases => %w(-a),
        :required => true, :default => '',
        :desc => "Name of the application whose maintenance page will be put up"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the environment can be found"
      method_option :verbose, :type => :boolean, :aliases => %w(-v),
        :desc => "Be verbose"
      def disable
        app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
        ui.info "Putting up maintenance page for '#{app_env.app.name}' in '#{app_env.environment.name}'"
        serverside_runner(app_env, options[:verbose]).put_up_maintenance_page.call(ui.out, ui.err)
      end

      desc "restart [--environment ENVIRONMENT]",
        "Restart the application servers without deploying."
      long_desc <<-DESC
        Restarts the application servers (e.g. Passenger, Unicorn, etc).

        Respects the maintenance_on_restart settings in the application's ey.yml.

        Note: Uses the version of the ey.yml currently checked out on the servers.
      DESC
      method_option :environment, :type => :string, :aliases => %w(-e),
        :required => true, :default => false,
        :desc => "Environment in which to deploy this application"
      method_option :app, :type => :string, :aliases => %w(-a),
        :required => true, :default => '',
        :desc => "Name of the application to deploy"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the environment can be found"
      method_option :verbose, :type => :boolean, :aliases => %w(-v),
        :desc => "Be verbose"
      def restart
        app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
        ui.info "Restarting servers on #{app_env.hierarchy_name}"
        if serverside_runner(app_env, options[:verbose]).restart.call(ui.out, ui.err)
          ui.info "Restart complete"
        else
          raise EY::Error, "Restart failed"
        end
      end

    end
  end
end
