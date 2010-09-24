# See the counterpart gem http://rubygems.org/gems/engineyard-metadata so your instances can be aware of each other.

module EY
  module Model
    class Metadata
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
      }
      
      attr_reader :data
      
      def initialize(data)
        @data = data
      end
      
      # Get metadata for this key.
      def get(key)
        if KEYS.include? key
          send key
        else
          data[key]
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
      
      # The public hostnames of all the utility servers, separated by commas.
      #
      # If you're on a solo app, it counts the solo as a utility.
      def utilities
        data['instances'].select { |i| %w{ util solo }.include? i['role'] }.map { |i| i['public_hostname'] }.sort.join ','
      end
      
      # The public hostname of the app_master.
      def app_master
        i = data['instances'].detect { |i| i['role'] == 'app_master' } ||
            data['instances'].detect { |i| i['role'] == 'solo' }
        i['public_hostname']
      end
      
      # The public hostname of the db_master,
      def db_master
        i = data['instances'].detect { |i| i['role'] == 'db_master' } ||
            data['instances'].detect { |i| i['role'] == 'solo' }
        i['public_hostname']
      end
    end
  end
end
