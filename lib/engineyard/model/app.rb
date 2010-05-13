module EY
  module Model
    class App < ApiStruct.new(:name, :repository_uri, :environments, :api)

      def self.from_hash(hash)
        super.tap do |app|
          app.environments = Environment.from_array(app.environments, :api => app.api)
        end
      end

      def one_and_only_environment
        if environments.size == 1
          environments.first
        end
      end

    end
  end
end
