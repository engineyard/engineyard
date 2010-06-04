module EY
  class CLI
    class Recipes < EY::Thor

      desc "recipes apply [ENV]", "Apply uploaded chef recipes on ENV"
      def apply(name = nil)
        environment = fetch_environment(name)
        environment.run_custom_recipes
        EY.ui.say "Uploaded recipes started for #{environment.name}"
      end

      desc "recipes upload [ENV]", "Upload custom chef recipes from the current directory to ENV"
      def upload(name = nil)
        environment = fetch_environment(name)
        environment.upload_recipes
        EY.ui.say "Recipes uploaded successfully for #{environment.name}"
      end

    end
  end

end
