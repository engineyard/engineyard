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

        @branch           = @environment.resolve_branch(options[:branch], options[:force]) ||
                            @current_branch ||
                            raise(DeployArgumentError)
      end

      def ensure_server_capable!(&block)
        @environment.ensure_eysd_present!(&block)
      end

      def run
        @environment.deploy!(@options[:app], @branch, @options[:migrate])
      end
    end
  end
end
