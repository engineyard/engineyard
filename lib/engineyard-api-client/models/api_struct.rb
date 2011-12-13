module EY
  class APIClient
    class ApiStruct < Struct

      def self.new(*args, &block)
        args = [:api] | args
        super(*args) do |*block_args|
          block.call(*block_args) if block

          def self.from_array(api, array, common_values = {})
            array.map do |values|
              from_hash(api, values.merge(common_values))
            end if array
          end

          def self.from_hash(api, attrs)
            return nil unless attrs
            new(api, attrs)
          end
        end
      end

      def initialize(api, attrs)
        self.api = api
        self.attributes = attrs
      end

      def attributes=(attrs)
        attrs.each do |key, val|
          setter = :"#{key}="
          if respond_to?(setter)
            send(setter, val)
          end
        end
      end

    end
  end
end
