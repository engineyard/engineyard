module EY
  class APIClient
    class Environment < ApiStruct.new(:id, :account, :name, :framework_env, :instances, :instances_count,
                                      :apps, :app_master, :username, :app_server_stack_name, :deployment_configurations,
                                      :load_balancer_ip_address, :api)

      attr_accessor :ignore_bad_master

      def self.from_hash(hash)
        super.tap do |env|
          env.username = hash['ssh_username']
          env.apps = App.from_array(env.apps, :api => env.api)
          env.account = Account.from_hash(env.account)
          env.instances = Instance.from_array(hash['instances'], :environment => env)
          env.app_master = Instance.from_hash(env.app_master.merge(:environment => env)) if env.app_master
        end
      end

      def self.from_array(*)
        Collections::Environments.new(super)
      end

      def logs
        Log.from_array(api_get("/environments/#{id}/logs")["logs"])
      end

      def app_master!
        master = app_master
        if master.nil?
          raise NoAppMasterError.new(name)
        elsif !ignore_bad_master && master.status != "running"
          raise BadAppMasterStatusError.new(master.status)
        end
        master
      end

      alias bridge! app_master!

      def app_environment_for(app)
        deploy_config     = deployment_configurations[app.name]

        migration_command = deploy_config && deploy_config['migrate']['command']
        perform_migration = deploy_config && deploy_config['migrate']['perform']

        AppEnvironment.from_hash({
          :app => app,
          :environment => self,
          :perform_migration => perform_migration,
          :migration_command => migration_command,
          :api => api,
        })
      end

      def rebuild
        api.request("/environments/#{id}/update_instances", :method => :put)
      end

      def run_custom_recipes
        api.request("/environments/#{id}/run_custom_recipes", :method => :put)
      end

      def download_recipes
        if File.exist?('cookbooks')
          raise EY::Error, "Could not download, cookbooks already exists"
        end

        require 'tempfile'
        tmp = Tempfile.new("recipes")
        tmp.write(api.request("/environments/#{id}/recipes"))
        tmp.flush
        tmp.close

        cmd = "tar xzf '#{tmp.path}' cookbooks"

        unless system(cmd)
          raise EY::Error, "Could not unarchive recipes.\nCommand `#{cmd}` exited with an error."
        end
      end

      def upload_recipes_at_path(recipes_path)
        recipes_path = Pathname.new(recipes_path)
        if recipes_path.exist?
          upload_recipes recipes_path.open('rb')
        else
          raise EY::Error, "Recipes file not found: #{recipes_path}"
        end
      end

      def tar_and_upload_recipes_in_cookbooks_dir
        require 'tempfile'
        unless File.exist?("cookbooks")
          raise EY::Error, "Could not find chef recipes. Please run from the root of your recipes repo."
        end

        recipes_file = Tempfile.new("recipes")
        cmd = "tar czf '#{recipes_file.path}' cookbooks/"

        unless system(cmd)
          raise EY::Error, "Could not archive recipes.\nCommand `#{cmd}` exited with an error."
        end

        upload_recipes(recipes_file)
      end

      def upload_recipes(file_to_upload)
        api.request("/environments/#{id}/recipes", {
          :method => :post,
          :params => {:file => file_to_upload}
        })
      end

      def shorten_name_for(app)
        name.gsub(/^#{Regexp.quote(app.name)}_/, '')
      end

      def launch
        Launchy.open(app_master!.hostname_url)
      end

      private

      def no_migrate?(hash)
        hash.key?('migrate') && hash['migrate'] == false
      end
    end
  end
end
