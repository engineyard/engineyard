module EY
  class CLI
    class API < EY::API

      def initialize(token = nil)
        @token = token
        @token ||= self.class.read_token
        @token ||= self.class.fetch_token
        raise EY::Error, "Sorry, we couldn't get your API token." unless @token
      end

      def request(*)
        begin
          super
        rescue EY::API::InvalidCredentials
          EY.ui.warn "Credentials rejected, please authenticate again"
          refresh
          retry
        end
      end

      def refresh
        @token = self.class.fetch_token
      end

      def environment_named(env_name, envs = self.environments)
        super || find_environment_by_unambiguous_substring(env_name, envs)
      end

      def self.fetch_token
        EY.ui.warn("The engineyard gem is prerelease software. Please do not use")
        EY.ui.warn("this tool to deploy to mission-critical environments, yet.")
        EY.ui.info("We need to fetch your API token, please login")
        begin
          email    = EY.ui.ask("Email: ")
          password = EY.ui.ask("Password: ", true)
          super(email, password)
        rescue EY::API::InvalidCredentials
          EY.ui.warn "Invalid username or password, please try again"
          retry
        end
      end

      private
      def find_environment_by_unambiguous_substring(env_name, envs)
        candidates = envs.find_all{|e| e.name[env_name] }
        if candidates.size > 1
          raise AmbiguousEnvironmentName.new(env_name, candidates.map {|e| e.name})
        end
        candidates.first
      end

    end
  end
end
