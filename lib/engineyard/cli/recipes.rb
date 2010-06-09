module EY
  class CLI
    class Recipes < EY::Thor
      desc "recipes apply [ENVIRONMENT]", <<-DESC
Run uploaded chef recipes on specified environment.

This is similar to '#{banner_base} rebuild' except Engine Yard's main
configuration step is skipped.
      DESC

      def apply(name = nil)
        environment = fetch_environment(name)
        environment.run_custom_recipes
        EY.ui.say "Uploaded recipes started for #{environment.name}"
      end

      desc "recipes upload [ENVIRONMENT]", <<-DESC
Upload custom chef recipes to specified environment.

The current directory should contain a subdirectory named "cookbooks" to be
uploaded.
      DESC

      def upload(name = nil)
        environment = fetch_environment(name)
        environment.upload_recipes
        EY.ui.say "Recipes uploaded successfully for #{environment.name}"
      end
    end
  end

end
