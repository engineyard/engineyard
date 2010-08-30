module EY
  class CLI
    class Recipes < EY::Thor
      desc "apply [--environment ENVIRONMENT]",
        "Run uploaded chef recipes on specified environment."
      long_desc <<-DESC
        This is similar to '#{banner_base} rebuild' except Engine Yard's main
        configuration step is skipped.
      DESC

      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment in which to apply recipes"
      def apply
        environment = fetch_environment_without_app(options[:environment])
        environment.run_custom_recipes
        EY.ui.say "Uploaded recipes started for #{environment.name}"
      end

      desc "upload [--environment ENVIRONMENT]",
        "Upload custom chef recipes to specified environment."
      long_desc <<-DESC
        The current directory should contain a subdirectory named "cookbooks" to be
        uploaded.
      DESC

      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment that will receive the recipes"
      def upload
        environment = fetch_environment_without_app(options[:environment])
        environment.upload_recipes
        EY.ui.say "Recipes uploaded successfully for #{environment.name}"
      end

      desc "download [--environment ENVIRONMENT]",
        "Download custom chef recipes from ENVIRONMENT into the current directory."
      long_desc <<-DESC
        The recipes will be unpacked into a directory called "cookbooks" in the
        current directory.

        If the cookbooks directory already exists, an error will be raised.
      DESC
      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment for which to download the recipes"
      def download
        environment = fetch_environment_without_app(options[:environment])
        environment.download_recipes
        EY.ui.say "Recipes downloaded successfully for #{environment.name}"
      end

    end
  end
end
