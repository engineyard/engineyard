module EY
  class CloudClient
    class ApiStruct < Struct
      def self.new(*args, &block)
        args = [:api] | args
        super(*args) do |*block_args|
          block.call(*block_args) if block

          def self.from_array(api, array, common_values = {})
            if array
              array.map do |values|
                from_hash(api, values.merge(common_values))
              end
            end
          end

          def self.from_hash(api, attrs_or_struct)
            return nil unless attrs_or_struct

            if attrs_or_struct.respond_to?(:attributes=)
              # already a model
              obj = attrs_or_struct
            elsif obj = api.registry.find(self, attrs_or_struct['id'])
              obj.attributes = attrs_or_struct
            else
              obj = new(api, attrs_or_struct)
              api.registry.set(self, obj)
            end
            obj
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
