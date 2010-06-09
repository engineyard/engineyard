module EY
  class CLI
    class Web < EY::Thor
      desc "web enable [ENVIRONMENT]", <<-HELP
Take down the maintenance page for the specified environment.

Note that a maintenance page exists for the entire environment. If you are
using multiple applications in a single environment, this command will re-enable
traffic for all of them.
      HELP

      def enable(env_name = nil)
        app         = api.app_for_repo!(repo)
        environment = fetch_environment(env_name, app)
        loudly_check_eysd(environment)
        EY.ui.info "Taking down maintenance page for #{environment.name}"
        environment.take_down_maintenance_page!(app)
      end

      desc "web disable [ENVIRONMENT]", <<-HELP
Put up the maintenance page for the specified environment.

The maintenance page is taken from the app currently being deployed. This means
that you can customize maintenance pages to tell users the reason for downtime
on every particular deploy.

Note that a maintenance page is put up for the entire environment. If you are
using multiple applications in a single environment, traffic for all of them
will be redirected to the maintenance page.

Maintenance pages searched for in order of decreasing priority:
* public/maintenance.html.custom
* public/maintenance.html.tmp
* public/maintenance.html
* public/system/maintenance.html.default
      HELP

      def disable(env_name = nil)
        app         = api.app_for_repo!(repo)
        environment = fetch_environment(env_name, app)
        loudly_check_eysd(environment)
        EY.ui.info "Putting up maintenance page for #{environment.name}"
        environment.put_up_maintenance_page!(app)
      end
    end
  end
end
