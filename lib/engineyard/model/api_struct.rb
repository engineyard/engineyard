module EY
  module Model
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
            members = new.members
            values = members.map{|a| hash.has_key?(a.to_sym) ? hash[a.to_sym] : hash[a] }
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
