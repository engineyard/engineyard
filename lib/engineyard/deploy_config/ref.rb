require 'engineyard/error'

module EY
  class DeployConfig
    class Ref

      def initialize(cli_opts, env_config, repo, ui)
        @cli_opts  = cli_opts
        @default   = env_config.branch
        @repo      = repo
        @force_ref = @cli_opts.fetch('force_ref', false)
        @ui        = ui

        if @force_ref.kind_of?(String)
          @ref, @force_ref = @force_ref, true
        else
          @ref = @cli_opts.fetch('ref', nil)
          @ref = nil if @ref == ''
        end
      end

      def when_inside_repo
        if !@force_ref && @ref && @default && @ref != @default
          raise BranchMismatchError.new(@default, @ref)
        elsif @force_ref && @ref && @default
          @ui.say "Default ref overridden with #{@ref.inspect}."
        end

        @ref || use_default || use_current_branch || raise(RefRequired.new(@cli_opts))
      end

      def use_default
        if @default
          @ui.say "Using default branch #{@default.inspect} from ey.yml."
          @default
        end
      end

      def use_current_branch
        if current = @repo.current_branch
          @ui.say "Using current HEAD branch #{current.inspect}."
          current
        end
      end

      # a.k.a. not in the correct repo
      #
      # returns the ref if it was passed in the cli opts.
      # or raise
      def when_outside_repo
        @ref or raise RefAndMigrateRequiredOutsideRepo.new(@cli_opts)
      end

    end
  end
end
