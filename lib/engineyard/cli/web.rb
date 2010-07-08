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
      def enable
        app         = fetch_app(options[:app])
        environment = fetch_environment(options[:environment], app)
        loudly_check_eydeploy(environment)
        EY.ui.info "Taking down maintenance page for '#{app.name}' in '#{environment.name}'"
        environment.take_down_maintenance_page(app, options[:verbose])
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
      def disable
        app         = fetch_app(options[:app])
        environment = fetch_environment(options[:environment], app)
        loudly_check_eydeploy(environment)
        EY.ui.info "Putting up maintenance page for '#{app.name}' in '#{environment.name}'"
        environment.put_up_maintenance_page(app, options[:verbose])
      end
    end
  end
end
