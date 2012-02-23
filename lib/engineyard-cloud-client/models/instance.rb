require 'escape'
require 'net/ssh'
require 'engineyard-serverside-adapter'
require 'engineyard-cloud-client/errors'

module EY
  class CloudClient
    class Instance < ApiStruct.new(:id, :role, :name, :status, :amazon_id, :public_hostname, :environment)
      alias :hostname :public_hostname

      def has_app_code?
        !["db_master", "db_slave"].include?(role.to_s)
      end

      def hostname_url
        "http://#{hostname}" if hostname
      end

    end
  end
end
