module EY
  class CloudClient
    class ModelRegistry
      def initialize
        @registry = Hash.new { |h,k| h[k] = {} }
      end

      def find(klass, id)
        if id
          @registry[klass][id]
        end
      end

      def set(klass, obj)
        if obj.respond_to?(:id)
          @registry[klass][obj.id] = obj
        end
      end
    end
  end
end
