module EY
  class Account
    class App < Struct.new(:name, :repository_url, :environments, :account)
      def self.from_hash(hash, account)
        new(
          hash["name"],
          hash["repository_uri"], # We use url canonically in the ey gem
          Environment.from_array(hash["environments"], account),
          account
        ) if hash && hash != "null"
      end

      def self.from_array(array, account)
        array.map{|n| from_hash(n, account) } if array && array != "null"
      end
    end
  end
end
