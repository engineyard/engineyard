# See the counterpart gem http://rubygems.org/gems/engineyard-metadata so your instances can be aware of each other.

module EY
  module Model
    class Metadata
      class UnknownKey < StandardError; end
      KEYS = %w{
        database_password
        database_username
        database_name
        database_host
        ssh_username
        app_servers
        db_servers
        utilities
        app_master
        db_master
        solo
        ssh_aliases
        app_slaves
        db_slaves
        environment_name
      }.sort
      
      attr_reader :environment
      attr_reader :data
      
      def initialize(environment, data)
        @environment = environment
        @data = data
      end
      
      # The name of the EngineYard AppCloud environment.
      #
      # Not to be confused with the application name or your Rails environment.
      def environment_name
        environment.name
      end
      
      # Get metadata for this key.
      def get(key)
        if KEYS.include? key
          retval = send key
          retval.nil? ? '' : retval
        else
          raise UnknownKey
        end
      end
      
      # Currently the same as SSH password.
      def database_password
        # data['ssh_password']
        raise "You currently can't get the database password (or any password) from the EngineYard AppCloud's API."
      end
      
      # Currently the same as the SSH username.
      def database_username
        data['ssh_username']
      end
      
      # For newly deployed applications, equal to the application name.
      def database_name
        data['apps'][0]['name']
      end
      
      # Public hostname where you should connect to the database.
      #
      # Currently the db master public hostname.
      def database_host
        db_master
      end
      
      # The username that is set on the environment in the GUI.
      def ssh_username
        data['ssh_username']
      end
      
      # The public hostnames of all the app servers, separated by commas.
      #
      # If you're on a solo app, it counts the solo as an app server.
      def app_servers
        data['instances'].select { |i| %w{ app_master app solo }.include? i['role'] }.map { |i| i['public_hostname'] }.sort.join ','
      end
      
      # The public hostnames of all the db servers, separated by commas.
      #
      # If you're on a solo app, it counts the solo as a db server.
      def db_servers
        data['instances'].select { |i| %w{ db_master db_slave solo }.include? i['role'] }.map { |i| i['public_hostname'] }.sort.join ','
      end
      
      # The public hostnames of all the db slaves, separated by commas.
      def db_slaves
        data['instances'].select { |i| i['role'] == 'db_slave' }.map { |i| i['public_hostname'] }.sort.join ','
      end
      
      # The public hostnames of all the app slaves (i.e. non-masters), separated by commas.
      def app_slaves
        data['instances'].select { |i| i['role'] == 'app' }.map { |i| i['public_hostname'] }.sort.join ','
      end
      
      # The public hostnames of all the utility servers, separated by commas.
      #
      # If you're on a solo app, it counts the solo as a utility.
      def utilities
        data['instances'].select { |i| %w{ util solo }.include? i['role'] }.map { |i| i['public_hostname'] }.sort.join ','
      end
      
      # The public hostname of the app_master.
      def app_master
        if x = data['instances'].detect { |i| i['role'] == 'app_master' }
          x['public_hostname']
        else
          solo
        end
      end
      
      # The public hostname of the db_master,
      def db_master
        if x = data['instances'].detect { |i| i['role'] == 'db_master' }
          x['public_hostname']
        else
          solo
        end
      end
      
      # The public hostname of the solo.
      def solo
        if x = data['instances'].detect { |i| i['role'] == 'solo' }
          x['public_hostname']
        end
      end
      
      # Aliases like 'my_env-app_master' or 'my_env-utilities-5' that go in .ssh/config
      #
      # For example:
      #   Host my_env-app_master
      #     Hostname ec2-111-111-111-111.compute-1.amazonaws.com
      #     User deploy
      #     StrictHostKeyChecking no
      def ssh_aliases
        counter = Hash.new 0
        %w{ app_master db_master db_slaves app_slaves utilities }.map do |role_group|
          send(role_group).split(',').map do |public_hostname|
            ssh_alias counter, role_group, public_hostname
          end
        end.flatten.join("\n")
      end
      
      private
      
      def ssh_alias(counter, role_group, public_hostname)
        id = case role_group
        when 'db_slaves', 'app_slaves', 'utilities'
          "#{role_group}-#{counter[role_group] += 1}"
        else
          role_group
        end
        %{Host #{environment_name}-#{id}
  Hostname #{public_hostname}
  User #{ssh_username}
  StrictHostKeyChecking no
}        
      end
    end
  end
end
