module EY
  class Account
    class ApiStruct < Struct
      def self.new(*args, &block)
        super(*args) do |*block_args|
          block.call(*block_args) if block

          def self.from_array(array, account = nil)
            array.map do |values|
              from_hash(values.merge(:account => account))
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
    end
  end
end
