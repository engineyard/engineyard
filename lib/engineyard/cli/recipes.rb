module EY
  class CLI
    class Recipes < EY::Thor
      desc "recipes apply [ENVIRONMENT]", <<-DESC
Run uploaded chef recipes on specified environment.

This is similar to '#{banner_base} rebuild' except Engine Yard's main
configuration step is skipped.
      DESC

      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment in which to apply recipes"
      def apply
        environment = fetch_environment(options[:environment])
        environment.run_custom_recipes
        EY.ui.say "Uploaded recipes started for #{environment.name}"
      end

      desc "recipes upload [ENVIRONMENT]", <<-DESC
Upload custom chef recipes to specified environment.

The current directory should contain a subdirectory named "cookbooks" to be
uploaded.
      DESC

      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment that will receive the recipes"
      def upload
        environment = fetch_environment(options[:environment])
        environment.upload_recipes
        EY.ui.say "Recipes uploaded successfully for #{environment.name}"
      end

      desc "recipes download [--environment ENVIRONMENT]", <<-DESC
Download custom chef recipes from ENVIRONMENT into the current directory.

The recipes will be unpacked into a directory called "cookbooks" in the
current directory.

If the cookbooks directory already exists, an error will be raised.
DESC
      method_option :environment, :type => :string, :aliases => %w(-e),
        :desc => "Environment for which to download the recipes"
      def download
        environment = fetch_environment(options[:environment])
        environment.download_recipes
        EY.ui.say "Recipes downloaded successfully for #{environment.name}"
      end

    end
  end
end
