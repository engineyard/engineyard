require 'engineyard/error'

module EY
  class APIClient
    module Collections
      class Abstract
        COLLAB_MESSAGE = <<-MSG
  \nThis error is due to having access to another account's resources via the collaboration feature.
  Specify --account ACCOUNT_NAME to resolve this ambiguity.
        MSG

        include Enumerable

        def initialize(contents)
          @contents = contents ? contents.dup.flatten : []
        end

        def each(&block)
          @contents.each(&block)
        end

        def to_a
          @contents
        end

        def named(name, account_name=nil)
          name = name.downcase
          account_name = account_name.downcase if account_name
          candidates = @contents.find_all do |x|
            name == x.name.downcase && (!account_name || account_name == x.account.name.downcase)
          end

          if candidates.size > 1
            raise ambiguous_error(name, candidates.map {|e| e.name}, COLLAB_MESSAGE )
          end
          candidates.first
        end

        def match_one(name_part)
          named(name_part) || find_by_unambiguous_substring(name_part)
        end

        def match_one!(name_part)
          match_one(name_part) or raise invalid_error(name_part)
        end

      private

        def find_by_unambiguous_substring(name_part)
          candidates = @contents.find_all{|e| e.name.downcase[name_part.downcase] }
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
end
