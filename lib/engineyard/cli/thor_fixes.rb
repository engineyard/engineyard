# This particular pile of monkeypatch can be removed once we have a
# thor that doesn't consume an argument for --no-migrate.
#
# A fix has been written and a pull request sent.
# The fix is
# http://github.com/smerritt/thor/commit/421b2e97684e67ee393a13b3873e1a784bb83f68

class ::Thor
  class Arguments
    private

    def no_or_skip?(arg)
      arg =~ /^--(no|skip)-([-\w]+)$/
      $2
    end

    def parse_string(name)
      if no_or_skip?(name)
        nil
      else
        shift
      end
    end

  end
end
