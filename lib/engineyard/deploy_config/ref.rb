require 'engineyard/error'

module EY
  class DeployConfig
    class Ref

      def initialize(cli_opts, env_config, repo)
        @cli_opts  = cli_opts
        @default   = env_config.branch
        @repo      = repo
        @force_ref = @cli_opts.fetch(:force_ref, false)

        if @force_ref.kind_of?(String)
          @ref, @force_ref = @force_ref, true
        else
          @ref = @cli_opts.fetch(:ref, nil)
        end
      end

      def when_inside_repo
        if !@force_ref && @ref && @default && @ref != @default
          raise BranchMismatchError.new(@default, @ref)
        end

        @ref || @default || @repo.current_branch || raise(RefRequired.new(@cli_opts))
      end

      # a.k.a. not in the correct repo
      #
      # returns the ref if it was passed in the cli opts.
      # yields the given block if not set
      def when_outside_repo
        @ref or raise RefAndMigrateRequiredOutsideRepo.new(@cli_opts)
      end

    end
  end
end
