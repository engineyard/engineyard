module EY
  class CloudClient
    class ResolverResult
      attr_reader :api, :matches, :errors, :suggestions

      def initialize(api, matches, errors, suggestions)
        @api = api
        @matches, @errors = matches, errors
        self.suggestions = suggestions
      end

      def one_match?()    matches.size == 1 end
      def no_matches?()   matches.empty?    end
      def many_matches?() matches.size > 1  end

      def one_match(&block)    one_match?    && block && block.call(matches.first)       end
      def no_matches(&block)   no_matches?   && block && block.call(errors, suggestions) end
      def many_matches(&block) many_matches? && block && block.call(matches)             end

      private

      def suggestions=(suggest)
        @suggestions = {}
        suggest && suggest.each do |key, val|
          @suggestions[key] = suggest_class(key).from_array(api, val) if val && !val.empty?
        end
        @suggestions
      end

      def suggest_class(key)
        case key.to_s
        when 'apps'             then EY::CloudClient::App
        when 'environments'     then EY::CloudClient::Environment
        when 'app_environments' then EY::CloudClient::AppEnvironment
        else raise "Unknown key: #{key}"
        end
      end
    end
  end
end
