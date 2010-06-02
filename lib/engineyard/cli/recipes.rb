module EY
  class CLI
    class Recipes < EY::Thor
      desc "recipes upload ENV", "Upload custom chef recipes from the current directory to ENV"
      def upload(name)
        if api.environments.match_one!(name).upload_recipes
          EY.ui.say "Recipes uploaded successfully"
        else
          EY.ui.error "Recipes upload failed"
        end
      end
    end
  end
end
