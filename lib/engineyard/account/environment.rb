module EY
  class Account
    class Environment < Struct.new(:id, :name, :instances_count, :apps, :app_master, :username, :account)
      def self.from_hash(hash, account)
        new(
          hash["id"],
          hash["name"],
          hash["instances_count"],
          App.from_array(hash["apps"], account),
          AppMaster.from_hash(hash["app_master"]),
          hash["ssh_username"],
          account
        ) if hash && hash != "null"
      end

      def self.from_array(array, account)
        array.map{|n| from_hash(n, account) } if array && array != "null"
      end

      def logs
        data = account.request("/environments/#{id}/logs")['logs']
        Log.from_array(data || [])
      end

      def configuration
        EY.config.environments[self.name]
      end
      alias_method :config, :configuration
    end
  end
end
