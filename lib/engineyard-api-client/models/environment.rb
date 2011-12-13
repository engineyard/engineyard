require 'engineyard-api-client/errors'

module EY
  class APIClient
    class Environment < ApiStruct.new(:id, :account, :name, :framework_env, :instances, :instances_count,
                                      :apps, :app_master, :username, :app_server_stack_name, :deployment_configurations,
                                      :load_balancer_ip_address)

      attr_accessor :ignore_bad_master

      def initialize(api, attrs)
        super
        self.instances = Instance.from_array(api, attrs['instances'] || attrs[:instances], :environment => self)
      end

      def self.from_array(*)
        Collections::Environments.new(super)
      end

      def apps=(collection_or_hashes)
        if Collections::Apps === collection_or_hashes
          super
        else
          super App.from_array(api, collection_or_hashes)
        end
      end

      def account=(account)
        super Account.from_hash(api, account)
      end

      def account_name
        account && account.name
      end

      def app_master=(hash_or_app_master)
        if Hash === hash_or_app_master
          super Instance.from_hash(api, hash_or_app_master.merge(:environment => self))
        else
          super
        end
      end

      def ssh_username=(user)
        self.username = user
      end

      def logs
        Log.from_array(api, api.request("/environments/#{id}/logs", :method => :get)["logs"])
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
        api.app_environments.detect { |app_env| app_env.environment == self && app_env.app == app }
      end

      def rebuild
        api.request("/environments/#{id}/update_instances", :method => :put)
      end

      def run_custom_recipes
        api.request("/environments/#{id}/run_custom_recipes", :method => :put)
      end

      def download_recipes
        if File.exist?('cookbooks')
          raise EY::APIClient::Error, "Could not download, cookbooks already exists"
        end

        require 'tempfile'
        tmp = Tempfile.new("recipes")
        tmp.write(api.request("/environments/#{id}/recipes"))
        tmp.flush
        tmp.close

        cmd = "tar xzf '#{tmp.path}' cookbooks"

        unless system(cmd)
          raise EY::APIClient::Error, "Could not unarchive recipes.\nCommand `#{cmd}` exited with an error."
        end
      end

      def upload_recipes_at_path(recipes_path)
        recipes_path = Pathname.new(recipes_path)
        if recipes_path.exist?
          upload_recipes recipes_path.open('rb')
        else
          raise EY::APIClient::Error, "Recipes file not found: #{recipes_path}"
        end
      end

      def tar_and_upload_recipes_in_cookbooks_dir
        require 'tempfile'
        unless File.exist?("cookbooks")
          raise EY::APIClient::Error, "Could not find chef recipes. Please run from the root of your recipes repo."
        end

        recipes_file = Tempfile.new("recipes")
        cmd = "tar czf '#{recipes_file.path}' cookbooks/"

        unless system(cmd)
          raise EY::APIClient::Error, "Could not archive recipes.\nCommand `#{cmd}` exited with an error."
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

      def no_migrate?(deploy_options)
        deploy_options.key?('migrate') && deploy_options['migrate'] == false
      end
    end
  end
end
