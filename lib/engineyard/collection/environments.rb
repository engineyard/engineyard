require 'engineyard/error'

module EY
  module Collection
    class Environments < Array

      def named(name)
        find {|e| e.name == name}
      end

      def named!(name)
        named(name) or raise EnvironmentError,
        "Environment '#{name}' can't be found\nYou can create it at #{EY.config.endpoint}"
      end

      def match_one(name_part)
        named(name_part) || find_by_unambiguous_substring(name_part)
      end

      def match_one!(name_part)
        match_one(name_part) or raise EnvironmentError,
        "Environment containing '#{name_part}' can't be found\nYou can create it at #{EY.config.endpoint}"
      end

    private
      def find_by_unambiguous_substring(name_part)
        candidates = find_all{|e| e.name[name_part] }
        if candidates.size > 1
          raise AmbiguousEnvironmentName.new(name_part, candidates.map {|e| e.name})
        end
        candidates.first
      end

    end
  end
end
