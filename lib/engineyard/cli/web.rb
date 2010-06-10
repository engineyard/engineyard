module EY
  class CLI
    class Web < EY::Thor

      desc "web enable [ENVIRONMENT]", "Take down the maintenance page for the current application on ENVIRONMENT"
      def enable(env_name = nil)
        app         = api.app_for_repo!(repo)
        environment = fetch_environment(env_name, app)
        loudly_check_eysd(environment)
        EY.ui.info "Taking down maintenance page for #{environment.name}"
        environment.take_down_maintenance_page!(app)
      end

      desc "web disable [ENVIRONMENT]", "Put up the maintenance page for the current application on ENVIRONMENT"
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
