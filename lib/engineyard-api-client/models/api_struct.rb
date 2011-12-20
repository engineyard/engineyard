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

          def self.from_hash(api, attrs_or_struct)
            return nil unless attrs_or_struct
            if attrs_or_struct.respond_to?(:attributes=)
              # already a model
              attrs_or_struct
            else
              new(api, attrs_or_struct)
            end
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
