module EY
  module Model
    class Environment < ApiStruct.new(:id, :name, :instances_count, :apps, :app_master, :username, :api)
      def self.from_hash(hash)
        super.tap do |env|
          env.username = hash['ssh_username']
          env.apps = App.from_array(env.apps, :api => env.api)
          env.app_master = Instance.from_hash(env.app_master.merge(:environment => env)) if env.app_master
        end
      end

      def self.from_array(array, extras={})
        Collection::Environments[*super]
      end

      def logs
        Log.from_array(api_get("/environments/#{id}/logs")["logs"])
      end

      def instances
        Instance.from_array(api_get("/environments/#{id}/instances")["instances"], :environment => self)
      end

      def rebuild
        api.request("/environments/#{id}/rebuild", :method => :put)
      end

      def upload_recipes(file_to_upload = recipe_file)
        api.request("/environments/#{id}/recipes",
          :method => :post,
          :params => {:file => file_to_upload}
          )
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

      def shorten_name_for(app)
        name.gsub(/^#{Regexp.quote(app.name)}_/, '')
      end
    end
  end
end
