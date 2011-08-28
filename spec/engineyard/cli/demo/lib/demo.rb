# The class name of EY::CLI::MyCommand is the final equivalent of "ey my_command"

module EY
  class CLI
    class Demo < EY::Thor
      
      desc "example [--environment/-e ENVIRONMENT]",
        "Put up the maintenance page for this application in the given environment."
      long_desc <<-DESC
      
      About time isn't it?
      
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
        app, environment = fetch_app_and_environment(options[:app], options[:environment], options[:account])
        EY.ui.info "Bla for '#{app.name}' in '#{environment.name}'"
        environment.put_up_maintenance_page(app, options[:verbose])
      end
      
    end
  end
end