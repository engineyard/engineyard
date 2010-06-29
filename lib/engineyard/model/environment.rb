module EY
  module Model
    class Environment < ApiStruct.new(:id, :name, :framework_env, :instances, :instances_count, :apps, :app_master, :username, :stack_name, :api)

      attr_accessor :ignore_bad_master

      def self.from_hash(hash)
        super.tap do |env|
          env.username = hash['ssh_username']
          env.apps = App.from_array(env.apps, :api => env.api)
          env.instances = Instance.from_array(hash['instances'], :environment => env)
          env.app_master = Instance.from_hash(env.app_master.merge(:environment => env)) if env.app_master
        end
      end

      def self.from_array(array, extras={})
        Collection::Environments[*super]
      end

      def logs
        Log.from_array(api_get("/environments/#{id}/logs")["logs"])
      end

      def app_master!
        master = app_master
        if master.nil?
          raise NoAppMaster.new(name)
        elsif !ignore_bad_master && master.status != "running"
          raise BadAppMasterStatus.new(master.status)
        end
        master
      end

      def ensure_eysd_present(&blk)
        app_master!.ensure_eysd_present(&blk)
      end

      def deploy(app, ref, migration_command=nil, verbose=false)
        app_master!.deploy(app, ref, migration_command, config, verbose)
      end

      def rollback(app, verbose=false)
        app_master!.rollback(app, config, verbose)
      end

      def take_down_maintenance_page(app, verbose=false)
        app_master!.take_down_maintenance_page(app, verbose)
      end

      def put_up_maintenance_page(app, verbose=false)
        app_master!.put_up_maintenance_page(app, verbose)
      end

      def rebuild
        api.request("/environments/#{id}/rebuild", :method => :put)
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

        cmd = "tar xzf '#{tmp.path}' cookbooks"

        unless system(cmd)
          raise EY::Error, "Could not unarchive recipes.\nCommand `#{cmd}` exited with an error."
        end
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
        cmd = "tar czf '#{tmp.path}' cookbooks/"

        unless system(cmd)
          raise EY::Error, "Could not archive recipes.\nCommand `#{cmd}` exited with an error."
        end

        tmp
      end

      def resolve_branch(branch, allow_non_default_branch=false)
        if !allow_non_default_branch && branch && default_branch && (branch != default_branch)
          raise BranchMismatch.new(default_branch, branch)
        end
        branch || default_branch
      end

      def configuration
        EY.config.environments[self.name]
      end
      alias_method :config, :configuration

      def default_branch
        EY.config.default_branch(name)
      end

      def shorten_name_for(app)
        name.gsub(/^#{Regexp.quote(app.name)}_/, '')
      end
    end
  end

end
