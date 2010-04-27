module EY
  class Account
    class App < Struct.new(:name, :repository_url, :environments, :account)
      def self.from_hash(hash, account)
        new(
          hash["name"],
          hash["repository_uri"], # We use url canonically in the ey gem
          Environment.from_array(hash["environments"], account),
          account
        ) if hash
      end

      def self.from_array(array, account)
        if array
          array.map{|n| from_hash(n, account) }
        else
          []
        end
      end
    end
  end
end
