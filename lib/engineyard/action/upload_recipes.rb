require 'engineyard/action/util'

module EY
  module Action
    class UploadRecipes
      extend Util

      def self.call(name)
        if account.upload_recipes_for(env_named(name))
          EY.ui.say "Recipes uploaded successfully"
        else
          EY.ui.error "Recipes upload failed"
        end
      end
    end
  end
end
