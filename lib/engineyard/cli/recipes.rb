module EY
  class CLI
    class Recipes < EY::Thor
      desc "apply [--environment ENVIRONMENT]",
        "Run chef recipes uploaded by the 'recipes upload' command on the specified environment."
      long_desc <<-DESC
        This is similar to '#{banner_base} rebuild' except Engine Yard's main
        configuration step is skipped.

        The cookbook uploaded by the 'recipes upload' command will be run when
        you run 'recipes apply'.
      DESC

      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment in which to apply recipes"
      method_option :account, :type => :string, :aliases => %w(-c),
        :desc => "Name of the account in which the environment can be found"
      def apply
        environment = fetch_environment(options[:environment], options[:account])
        environment.run_custom_recipes
        EY.ui.say "Uploaded recipes started for #{environment.name}"
      end

      desc "upload [--environment ENVIRONMENT]",
        "Upload custom chef recipes to specified environment so they can be applied."
      long_desc <<-DESC
        The current working directory should contain a subdirectory named "cookbooks"
        that is the collection of recipes to be uploaded.

        The uploaded cookbook will be run when executing 'recipes apply'.
      DESC

      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment that will receive the recipes"
      method_option :account, :type => :string, :aliases => %w(-c),
        :desc => "Name of the account in which the environment can be found"
      def upload
        environment = fetch_environment(options[:environment], options[:account])
        environment.upload_recipes
        EY.ui.say "Recipes uploaded successfully for #{environment.name}"
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
