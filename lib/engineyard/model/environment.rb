module EY
  module Model
    class Environment < ApiStruct.new(:id, :account, :name, :framework_env, :instances, :instances_count, :apps, :app_master, :username, :stack_name, :api)

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
        Collection::Environments[*super]
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

      def deploy(app, ref, deploy_options={})
        app_master!.deploy(app,
          ref,
          migration_command(deploy_options),
          config.merge(deploy_options['extras']),
          deploy_options['verbose'])
      end

      def rollback(app, extra_deploy_hook_options={}, verbose=false)
        app_master!.rollback(app,
          config.merge(extra_deploy_hook_options),
          verbose)
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
          raise BranchMismatchError.new(default_branch, branch)
        end
        branch || default_branch
      end

      def configuration
        EY.config.environments[self.name] || {}
      end
      alias_method :config, :configuration

      def default_branch
        EY.config.default_branch(name)
      end

      def shorten_name_for(app)
        name.gsub(/^#{Regexp.quote(app.name)}_/, '')
      end

      private

      def migration_command(deploy_options)
        # regarding deploy_options['migrate']:
        #
        # missing means migrate how the yaml file says to
        # nil means don't migrate
        # true means migrate w/custom command (if present) or default
        # a string means migrate with this specific command
        if deploy_options.has_key?('migrate')
          migration_command_from_command_line(deploy_options)
        else
          migration_command_from_config
        end
      end

      def migration_command_from_config
        if config.has_key?('migrate')
          if config['migrate']
            default_migration_command
          else
            nil
          end
        else
          default_migration_command
        end
      end

      def migration_command_from_command_line(deploy_options)
        if deploy_options['migrate'].nil?
          nil
        elsif deploy_options['migrate'].respond_to?(:to_str)
          deploy_options['migrate'].to_str
        else
          default_migration_command
        end
      end


      def default_migration_command
        config['migration_command'] || 'rake db:migrate --trace'
      end

    end
  end
end
