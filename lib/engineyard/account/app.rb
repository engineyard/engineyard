module EY
  class Account
    class App < ApiStruct.new(:name, :repository_uri, :environments, :account)

      def self.from_hash(hash)
        super.tap do |app|
          app.environments = Environment.from_array(app.environments, app.account)
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
