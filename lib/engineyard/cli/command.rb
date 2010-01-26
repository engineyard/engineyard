module EY
  module CLI
    class Command
      def self.token
        @token ||= EY::CLI::Authentication.get_token
      end

      def self.run(args)
        raise "#{self.inspect} does not implement the run method."
      end

      def self.short_usage
        raise "#{self.inspect} does not implement the short_usage method."
      end

      # def self.usage
      #   "More elaborate instructions for using this command"
      # end

      def self.inherited(subclass)
        superclass.inherited(subclass) if superclass.respond_to? :inherited
        @subclasses ||= []
        @subclasses << subclass
      end

      def self.subclasses
        @subclasses
      end
    end
  end
end