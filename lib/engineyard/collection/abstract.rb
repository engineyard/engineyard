require 'engineyard/error'

module EY
  module Collection
    class Abstract < Array

      def named(name)
        find {|x| x.name == name }
      end

      def match_one(name_part)
        named(name_part) || find_by_unambiguous_substring(name_part)
      end

      def match_one!(name_part)
        match_one(name_part) or raise invalid_error(name_part)
      end

    private

      def find_by_unambiguous_substring(name_part)
        candidates = find_all{|e| e.name[name_part] }
        if candidates.size > 1
          raise ambiguous_error(name_part, candidates.map {|e| e.name})
        end
        candidates.first
      end

      class << self
        attr_accessor :invalid_error, :ambiguous_error
      end

      def invalid_error(*args, &blk)
        self.class.invalid_error.new(*args, &blk)
      end

      def ambiguous_error(*args, &blk)
        self.class.ambiguous_error.new(*args, &blk)
      end

    end
  end
end
