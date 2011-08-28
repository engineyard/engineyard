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
        :desc => "Environment in which to apply recipes"
      method_option :account, :type => :string, :aliases => %w(-c),
        :desc => "Name of the account in which the environment can be found"
      def apply
        environment = fetch_environment(options[:environment], options[:account])
        apply_recipes(environment)
      end

      desc "upload [--environment ENVIRONMENT]",
        "Upload custom chef recipes to specified environment so they can be applied."
      long_desc <<-DESC
        Make an archive of the "cookbooks/" subdirectory in your current working
        directory and upload it to AppCloud's recipe storage.

        Alternatively, specify a .tgz of a cookbooks/ directory yourself as follows:

        $ #{banner_base} recipes upload -f path/to/recipes.tgz

        The uploaded cookbooks will be run when executing '#{banner_base} recipes apply'
        and also automatically each time you update/rebuild your instances.
      DESC

      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment that will receive the recipes"
      method_option :account, :type => :string, :aliases => %w(-c),
        :desc => "Name of the account in which the environment can be found"
      method_option :apply, :type => :boolean,
        :desc => "Apply the recipes immediately after they are uploaded"
      method_option :file, :type => :string, :aliases => %w(-f),
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
          EY.ui.say "Uploaded recipes started for #{environment.name}"
        end

        def upload_recipes(environment, filename)
          if options[:file]
            environment.upload_recipes_at_path(options[:file])
            EY.ui.say "Recipes file #{options[:file]} uploaded successfully for #{environment.name}"
          else
            environment.tar_and_upload_recipes_in_cookbooks_dir
            EY.ui.say "Recipes in cookbooks/ uploaded successfully for #{environment.name}"
          end
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
        :desc => "Environment for which to download the recipes"
      method_option :account, :type => :string, :aliases => %w(-c),
        :desc => "Name of the account in which the environment can be found"
      def download
        environment = fetch_environment(options[:environment], options[:account])
        environment.download_recipes
        EY.ui.say "Recipes downloaded successfully for #{environment.name}"
      end

    end
  end
end
