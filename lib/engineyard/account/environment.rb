module EY
  class Account
    class Environment < ApiStruct.new(:id, :name, :instances_count, :apps, :app_master, :username, :account)
      def self.from_hash(hash)
        super.tap do |env|
          env.username = hash['ssh_username']
          env.apps = App.from_array(env.apps, :account => env.account)
          env.app_master = Instance.from_hash(env.app_master.merge(:environment => env)) if env.app_master
        end
      end

      def logs
        account.logs_for(self)
      end

      def instances
        account.instances_for(self)
      end

      def rebuild
        account.rebuild(self)
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
