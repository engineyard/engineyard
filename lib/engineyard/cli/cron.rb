module EY
  class CLI
    class Cron < EY::Thor
      desc "list [--environment ENVIRONMENT]", "List cron configuration for the environment."
      method_options :name => :default
      long_desc <<-DESC
        Manage your crontab configuration.
      DESC
      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment in which to roll back the application"
      method_option :account, :type => :string, :aliases => %w(-c),
        :desc => "Name of the account in which the environment can be found"
      method_option :verbose, :type => :boolean, :aliases => %w(-v),
        :desc => "Be verbose"
      def list
        environment = fetch_environment(options[:environment], options[:account])

        EY.ui.say "Cron for #{environment.name}:"
        EY.ui.say EY::Model::Cron.header
        environment.crons.each do |cron|
          EY.ui.say cron.crontab
        end
      end

      desc "add NAME COMMAND CRONTAB [--environment ENVIRONMENT]", "Add a complex/raw crontab."
      method_options :name => :default
      long_desc <<-DESC
        Add a complex/raw crontab to an environment.
        
        Example usage:
        * #{banner_base} cron add 'complex hourly' '/path/to/some/command' '0 * * * *'
      DESC
      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment in which to roll back the application"
      method_option :account, :type => :string, :aliases => %w(-c),
        :desc => "Name of the account in which the environment can be found"
      method_option :verbose, :type => :boolean, :aliases => %w(-v),
        :desc => "Be verbose"
      def add(name, command, crontab)
        environment = fetch_environment(options[:environment], options[:account])

        EY.ui.say "Cron added to #{environment.name}.", :green
      end

    end
  end
end