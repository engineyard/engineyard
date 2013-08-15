module EY
  class CLI
    class Vars < EY::Thor
      desc "show",
        "List all the vars"
      method_option :environment, :type => :string, :aliases => %w(-e),
        :required => true, :default => '',
        :desc => "Environment where the application is deployed"
      method_option :app, :type => :string, :aliases => %w(-a),
        :required => true, :default => '',
        :desc => "Name of the application"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the application can be found"
      def show
        app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
        ui.vars(app_env.vars, app_env.vars_resolved)
      end
      map :ls => :show
      map :list => :show

      desc "set --namespace NAMESPACE key:val key2:val2",
        "Set a hash of vars to a namespace"
      method_option :environment, :type => :string, :aliases => %w(-e),
        :required => true, :default => '',
        :desc => "Environment where the application is deployed"
      method_option :app, :type => :string, :aliases => %w(-a),
        :required => true, :default => '',
        :desc => "Name of the application"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the application can be found"
      method_option :namespace, :type => :string, :aliases => %w(-n), :default => 'user',
        :desc => "Namespace for these values (defaults to user)"
      argument :vars, :type => :hash, :optional => true,
        :desc => "value pairs. Ex: foo:bar red:blue"
      def set
        if vars.nil? || vars.empty?
          raise ArgumentError, "Please specify vars, Ex: foo:bar"
        end
        namespace = options[:namespace]
        app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
        app_env.vars[namespace] = vars
        api.update_vars(app_env)
        ui.info "Vars updated:"
        ui.vars(app_env.vars, app_env.vars_resolved)
      end

      desc "delete --namespace NAMESPACE",
        "Delete a vars namespace"
      method_option :environment, :type => :string, :aliases => %w(-e),
        :required => true, :default => '',
        :desc => "Environment where the application is deployed"
      method_option :app, :type => :string, :aliases => %w(-a),
        :required => true, :default => '',
        :desc => "Name of the application"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the application can be found"
      method_option :namespace, :type => :string, :aliases => %w(-n), :required => true,
        :desc => "Namespace to delete"
      def delete
        app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
        ui.info "Deleting vars at '#{options[:namespace]}'"
        app_env.vars.delete(options[:namespace])
        ui.vars(app_env.vars, app_env.vars_resolved)
      end

      desc "alias --namespace NAMESPACE --addon ADDON",
        "Make an addon available via an alias"
      method_option :environment, :type => :string, :aliases => %w(-e),
        :required => true, :default => '',
        :desc => "Environment where the application is deployed"
      method_option :app, :type => :string, :aliases => %w(-a),
        :required => true, :default => '',
        :desc => "Name of the application"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the application can be found"
      method_option :namespace, :type => :string, :aliases => %w(-n),
        :required => true,
        :desc => "Namespace to delete"
      method_option :addon, :type => :string,
        :required => true,
        :desc => "Addon and key name to fetch the value from, example: 'new_relic:license_key'"
      def alias
        app_env = fetch_app_environment(options[:app], options[:environment], options[:account])
        ui.info "aliasing"
        app_env.vars[options[:namespace]] = "Addon:#{options[:addon]}"
        api.update_vars(app_env)
        ui.info "Vars updated:"
        ui.vars(app_env.vars, app_env.vars_resolved)
      end
    end
  end
end
