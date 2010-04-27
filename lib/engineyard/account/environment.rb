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
        ) if hash
      end

      def self.from_array(array, account)
        if array
          array.map{|n| from_hash(n, account) }
        else
          []
        end
      end

      def logs
        account.logs_for(self)
      end

      def instances
        account.instances_for(self)
      end

      def recipe_file
        require 'tempfile'
        unless File.exist?("cookbooks")
          raise EY::Error, "Could not find chef recipes. Please run from the root of your recipes repo."
        end

        tmp = Tempfile.new("recipes")
        cmd = "git archive --format=tar HEAD cookbooks | gzip > #{tmp.path}"

        unless system(cmd)
          raise EY::Error, "Could not archive recipes.\nCommand `#{cmd}` exited with an error."
        end

        tmp
      end

      def configuration
        EY.config.environments[self.name]
      end
      alias_method :config, :configuration
    end
  end
end
