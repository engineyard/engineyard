module EY
  class Account
    class AppMaster < Struct.new(:status, :public_hostname)
      def self.from_hash(hash)
        new(
          hash["status"],
          hash["public_hostname"]
        ) if hash && hash != "null"
      end
    end
  end
end
