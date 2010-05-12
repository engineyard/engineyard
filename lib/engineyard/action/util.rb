module EY
  module Action
    module Util

    protected

      def account
        # XXX it stinks that we have to use EY::CLI::API explicitly
        # here; I don't want to have this lateral Action --> CLI reference
        @account ||= EY::Account.new(EY::CLI::API.new)
      end

      def repo
        @repo ||= EY::Repo.new
      end

    end
  end
end
