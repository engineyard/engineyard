module EY
  module Model
    class Deploy
      #
      # options :environment, :app, :branch, :current_branch, :force, :migrate
      #
      def initialize(options)
        @options          = options

        @environment      = @options[:environment]
        @specified_branch = @options[:branch]
        @current_branch   = @options[:current_branch]

        @default_branch   = @environment.default_branch
        @branch           = resolve_branch
      end

      def ensure_server_capable!(&block)
        @environment.ensure_eysd_present!(&block)
      end

      def run
        @environment.deploy!(@options[:app], @branch, @options[:migrate])
      end

      private

      def resolve_branch
        if !@options[:force] && @specified_branch && @default_branch && (@specified_branch != @default_branch)
          raise BranchMismatch.new(@default_branch, @specified_branch)
        end
        @specified_branch || @default_branch || @current_branch || raise(DeployArgumentError)
      end
    end
  end
end
