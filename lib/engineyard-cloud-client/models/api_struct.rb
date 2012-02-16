module EY
  class CloudClient
    class ApiStruct < Struct
      def self.models
        @models ||= []
      end

      # Used by tests to reset all descendent's registries
      def self.reset_registries
        models.each { |model| model.reset_registry }
      end

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
            else
              id = attrs_or_struct['id']
              if id && registry[id]
                obj = registry[id]
                obj.attributes = attrs_or_struct
                obj
              else
                obj = new(api, attrs_or_struct)
              end
            end
            obj
          end

          def self.registry
            @registry ||= {}
          end

          def self.reset_registry
            @registry = {}
          end

          def self.register(obj)
            if obj.respond_to?(:id)
              registry[obj.id] = obj
            end
          end

          def self.inherited(sub)
            ApiStruct.models << sub
          end
        end
      end

      def initialize(api, attrs)
        self.api = api
        self.attributes = attrs
        self.class.register(self)
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
