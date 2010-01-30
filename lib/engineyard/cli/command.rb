module EY
  module CLI
    class Command
      class << self
        def run(args)
          raise "#{self.inspect} does not implement the run method."
        end

        def short_usage
          raise "#{self.inspect} does not implement the short_usage method."
        end

        # def self.usage
        #   "More elaborate instructions for using this command"
        # end

      private
        def token
          @token ||= EY::CLI.authenticate
        end

        def repo_url
          @repo_url ||= EY::Repo.new.repo_url
        end

        def config
          @config ||= EY::Config.new
        end

        def inherited(subclass)
          superclass.inherited(subclass) if superclass.respond_to? :inherited
          @subclasses ||= []
          @subclasses << subclass
        end

        def subclasses
          @subclasses
        end
      end
    end
  end
end