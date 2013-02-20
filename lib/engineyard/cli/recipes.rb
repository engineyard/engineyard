require 'tempfile'

module EY
  class CLI
    class Recipes < EY::Thor
      desc "apply [--environment ENVIRONMENT]",
        "Run chef recipes uploaded by '#{banner_base} recipes upload' on the specified environment."
      long_desc <<-DESC
        This is similar to '#{banner_base} rebuild' except Engine Yard's main
        configuration step is skipped.

        The cookbook uploaded by the '#{banner_base} recipes upload' command will be run when
        you run '#{banner_base} recipes apply'.
      DESC

      method_option :environment, :type => :string, :aliases => %w(-e),
        :required => true, :default => '',
        :desc => "Environment in which to apply recipes"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the environment can be found"
      def apply
        environment = fetch_environment(options[:environment], options[:account])
        apply_recipes(environment)
      end

      desc "upload [--environment ENVIRONMENT]",
        "Upload custom chef recipes to specified environment so they can be applied."
      long_desc <<-DESC
        Make an archive of the "cookbooks/" subdirectory in your current working
        directory and upload it to Engine Yard Cloud's recipe storage.

        Alternatively, specify a .tgz of a cookbooks/ directory yourself as follows:

        $ #{banner_base} recipes upload -f path/to/recipes.tgz

        The uploaded cookbooks will be run when executing '#{banner_base} recipes apply'
        and also automatically each time you update/rebuild your instances.
      DESC

      method_option :environment, :type => :string, :aliases => %w(-e),
        :required => true, :default => '',
        :desc => "Environment that will receive the recipes"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the environment can be found"
      method_option :apply, :type => :boolean,
        :desc => "Apply the recipes immediately after they are uploaded"
      method_option :file, :type => :string, :aliases => %w(-f),
        :required => true, :default => '',
        :desc => "Specify a gzipped tar file (.tgz) for upload instead of cookbooks/ directory"
      def upload
        environment = fetch_environment(options[:environment], options[:account])
        upload_recipes(environment, options[:file])
        if options[:apply]
          apply_recipes(environment)
        end
      end

      no_tasks do
        def apply_recipes(environment)
          environment.run_custom_recipes
          ui.info "Uploaded recipes started for #{environment.name}"
        end

        def upload_recipes(environment, filename)
          if filename && filename != ''
            environment.upload_recipes_at_path(filename)
            ui.info "Recipes file #{filename} uploaded successfully for #{environment.name}"
          else
            path = cookbooks_dir_archive_path
            environment.upload_recipes_at_path(path)
            ui.info "Recipes in cookbooks/ uploaded successfully for #{environment.name}"
          end
        end

        def cookbooks_dir_archive_path
          unless FileTest.exist?("cookbooks")
            raise EY::Error, "Could not find chef recipes. Please run from the root of your recipes repo."
          end

          recipes_file = Tempfile.new("recipes")
          cmd = "tar czf '#{recipes_file.path}' cookbooks/"

          unless system(cmd)
            raise EY::Error, "Could not archive recipes.\nCommand `#{cmd}` exited with an error."
          end
          recipes_file.path
        end
      end

      desc "download [--environment ENVIRONMENT]",
        "Download a copy of the custom chef recipes from this environment into the current directory."
      long_desc <<-DESC
        The recipes will be unpacked into a directory called "cookbooks" in the
        current directory. This is the opposite of 'recipes upload'.

        If the cookbooks directory already exists, an error will be raised.
      DESC
      method_option :environment, :type => :string, :aliases => %w(-e),
        :required => true, :default => '',
        :desc => "Environment for which to download the recipes"
      method_option :account, :type => :string, :aliases => %w(-c),
        :required => true, :default => '',
        :desc => "Name of the account in which the environment can be found"
      def download
        if File.exist?('cookbooks')
          raise EY::Error, "Cannot download recipes, cookbooks directory already exists."
        end

        environment = fetch_environment(options[:environment], options[:account])

        recipes = environment.download_recipes
        cmd = "tar xzf '#{recipes.path}' cookbooks"

        if system(cmd)
          ui.info "Recipes downloaded successfully for #{environment.name}"
        else
          raise EY::Error, "Could not unarchive recipes.\nCommand `#{cmd}` exited with an error."
        end
      end

    end
  end
end
