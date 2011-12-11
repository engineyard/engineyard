module EY
  class APIClient
    class ApiStruct < Struct

      def self.new(*args, &block)
        super(*args) do |*block_args|
          block.call(*block_args) if block

          def self.from_array(array, common_values = {})
            array.map do |values|
              from_hash(values.merge(common_values))
            end if array
          end

          def self.from_hash(hash)
            return nil unless hash
            # in ruby 1.8, #members is an array of strings
            # in ruby 1.9, #members is an array of symbols
            members = new.members.map {|m| m.to_sym}
            values = members.map{|a| hash.has_key?(a) ? hash[a] : hash[a.to_s] }
            new(*values)
          end

        end
      end

      def api_get(uri, options = {})
        api.request(uri, options.merge(:method => :get))
      end

    end
  end
end
